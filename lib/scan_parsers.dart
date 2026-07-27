/// ML Kit OCR 텍스트 → 구조화 데이터 규칙 파서 (무료 모드용)
library;

class ScannedItem {
  String name;
  double qty;
  String unit;
  double price;
  ScannedItem({
    required this.name,
    this.qty = 1,
    this.unit = '개',
    this.price = 0,
  });
}

class ScannedReceipt {
  String store = '';
  String date = '';
  List<ScannedItem> items = [];
  double total = 0;
}

class ScannedMenuLine {
  String name;
  double qty;
  double amount;
  ScannedMenuLine({required this.name, this.qty = 0, this.amount = 0});
}

class ScannedSalesReport {
  String date = '';
  List<ScannedMenuLine> menus = [];
  double total = 0;
}

class ScannedBizCert {
  String bizNumber = '';
  String storeName = '';
  String ownerName = '';
  String address = '';
}

double _num(String s) =>
    double.tryParse(s.replaceAll(',', '').replaceAll('원', '').trim()) ?? 0;

/// OCR 텍스트로 문서 종류 자동 판별 (무료 모드용)
/// 반환: receipt / salesReport / bizCert / menu / unknown
String classifyDocument(String text) {
  final t = text.replaceAll(' ', '').toLowerCase();

  // 1) 사업자등록증: 확실한 키워드
  if (t.contains('사업자등록증') ||
      (t.contains('등록번호') && t.contains('상호')) ||
      (RegExp(r'\d{3}-\d{2}-\d{5}').hasMatch(t) &&
          (t.contains('대표자') || t.contains('개업') || t.contains('소재지')))) {
    return 'bizCert';
  }

  int salesScore = 0;
  int receiptScore = 0;
  int menuScore = 0;

  // 2) 매출일보: 확실한 신호 (강함)
  for (final w in ['영업일보', '일일매출', '매출일보', '매출일계', '일계표', '매출집계',
      '판매집계', '마감정산', '정산표', '정산서', '매출현황', '매출요약', '매출분석',
      '메뉴별매출', '상품별매출', '메뉴별판매', '상품별판매', '포스마감', '영업마감']) {
    if (t.contains(w)) salesScore += 3;
  }
  // 매출일보: 보조 신호
  for (final w in ['총매출', '순매출', '매출합계', '매출액', '매출내역', '매출건수',
      '카드매출', '현금매출', '객단가', '주문건수', '판매수량', '판매금액',
      '결제수단', '시간대별', '테이블', '회전율', '할인액', '건수']) {
    if (t.contains(w)) salesScore += 2;
  }
  if (t.contains('일보')) salesScore += 3;
  if (t.contains('마감')) salesScore += 2;
  if (t.contains('정산')) salesScore += 2;
  if (t.contains('매출')) salesScore += 1;
  // 카드매출 + 현금매출 동시 등장 = 일보 확정급
  if (t.contains('카드매출') && t.contains('현금매출')) salesScore += 4;

  // 3) 영수증/구매: 확실한 신호 (영수증에만 나오는 단어)
  for (final w in ['영수증', '카드승인', '승인번호', '승인금액', '거스름', '받은금액',
      '거래명세', '납품서', '교환/환불', '반품', '일시불', '할부']) {
    if (t.contains(w)) receiptScore += 3;
  }
  // 영수증: 보조 신호 (일보에도 자주 나오는 단어라 약하게)
  for (final w in ['부가세', '단가', '공급가액', '면세', '과세물품', '결제금액', '신용카드']) {
    if (t.contains(w)) receiptScore += 1;
  }

  // 4) 메뉴판 신호: "이름 + 4자리이상 가격" 줄이 많고 수량 열이 없음
  int priceLines = 0;
  int qtyPriceLines = 0;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (RegExp(r'^(.+?)[\s.·]+([\d,]{4,})\s*원?$').hasMatch(line)) {
      priceLines++;
    }
    if (RegExp(r'^(.+?)\s+(\d{1,4})\s+([\d,]{3,})$').hasMatch(line)) {
      qtyPriceLines++;
    }
  }
  if (priceLines >= 4 && qtyPriceLines <= 1) menuScore += 3;
  if (t.contains('메뉴')) menuScore += 1;

  // "수량 금액" 줄이 많으면 영수증 또는 일보
  if (qtyPriceLines >= 2) {
    if (salesScore > 0) {
      salesScore += 2;
    } else {
      receiptScore += 1;
    }
  }

  // 동점이면 '매출' 단어 있을 때 일보 우선
  if (salesScore == receiptScore && salesScore > 0 && t.contains('매출')) {
    salesScore += 1;
  }

  final best = [
    ('salesReport', salesScore),
    ('receipt', receiptScore),
    ('menu', menuScore),
  ]..sort((a, b) => b.$2.compareTo(a.$2));

  if (best.first.$2 == 0) {
    // 신호 전혀 없으면: 가격 줄 있으면 영수증 추정, 없으면 unknown
    return qtyPriceLines >= 1 || priceLines >= 2 ? 'receipt' : 'unknown';
  }
  return best.first.$1;
}

/// 날짜 추출 (2025-01-03, 2025.01.03, 2025/01/03, 01/03 등)
String extractDate(String text) {
  final full = RegExp(r'(20\d{2})[-./년\s]{1,2}(\d{1,2})[-./월\s]{1,2}(\d{1,2})')
      .firstMatch(text);
  if (full != null) {
    final y = full.group(1)!;
    final m = full.group(2)!.padLeft(2, '0');
    final d = full.group(3)!.padLeft(2, '0');
    return '$y-$m-$d';
  }
  return '';
}

const _skipWords = [
  '합계', '합 계', '총액', '총 액', '소계', '부가세', '과세', '면세', '봉사료',
  '카드', '현금', '승인', '거스름', '받은', '결제', '할인', '포인트',
  '사업자', '대표', '전화', 'tel', '주소', '감사', '교환', '환불', '번호',
  '매출', '금액', '수량', '단가', '품명', '상품명', '일자', '날짜', '영수증',
];

bool _isSkipLine(String line) {
  final l = line.replaceAll(' ', '').toLowerCase();
  return _skipWords.any((w) => l.contains(w.replaceAll(' ', '')));
}

/// 영수증 파싱: "품목 수량 단가 금액" 또는 "품목 금액" 줄 인식
ScannedReceipt parseReceiptText(String text) {
  final r = ScannedReceipt();
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (lines.isNotEmpty) {
    // 첫 1~2줄 중 숫자 아닌 줄 = 매장명 후보
    for (final l in lines.take(3)) {
      if (!RegExp(r'^\d').hasMatch(l) && l.length >= 2 && !_isSkipLine(l)) {
        r.store = l;
        break;
      }
    }
  }
  r.date = extractDate(text);

  // 총액: "합계 45,000" 패턴
  final totalMatch = RegExp(r'(?:합\s*계|총\s*액|총합계|결제금액)\D*([\d,]{3,})')
      .firstMatch(text);
  if (totalMatch != null) r.total = _num(totalMatch.group(1)!);

  for (final line in lines) {
    if (_isSkipLine(line)) continue;

    // 패턴 1: 이름 수량 단가 금액 (예: 돼지고기 2 12,000 24,000)
    var m = RegExp(
            r'^(.+?)\s+(\d{1,3})\s+([\d,]{3,})\s+([\d,]{3,})$')
        .firstMatch(line);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.length < 2 || RegExp(r'^[\d,.-]+$').hasMatch(name)) continue;
      r.items.add(ScannedItem(
        name: name,
        qty: _num(m.group(2)!),
        price: _num(m.group(3)!),
      ));
      continue;
    }

    // 패턴 2: 이름 금액 (예: 두부 3,500)
    m = RegExp(r'^(.+?)\s+([\d,]{4,})$').firstMatch(line);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.length < 2 || RegExp(r'^[\d,.-]+$').hasMatch(name)) continue;
      // 수량 표기가 이름에 포함된 경우 (예: 두부 2개)
      final qtyIn = RegExp(r'(.+?)\s*(\d+)\s*(개|봉|팩|박스|병|캔|ea)$',
              caseSensitive: false)
          .firstMatch(name);
      if (qtyIn != null) {
        r.items.add(ScannedItem(
          name: qtyIn.group(1)!.trim(),
          qty: _num(qtyIn.group(2)!),
          unit: qtyIn.group(3)!,
          price: _num(m.group(2)!),
        ));
      } else {
        r.items.add(ScannedItem(name: name, price: _num(m.group(2)!)));
      }
    }
  }

  if (r.total == 0) {
    r.total = r.items.fold(0.0, (s, i) => s + i.price * i.qty);
  }
  return r;
}

/// 포스 일보 파싱: "메뉴명 수량 금액" 줄 인식
ScannedSalesReport parseSalesReportText(String text) {
  final r = ScannedSalesReport();
  r.date = extractDate(text);

  final totalMatch = RegExp(r'(?:합\s*계|총\s*매출|총\s*액)\D*([\d,]{3,})')
      .firstMatch(text);
  if (totalMatch != null) r.total = _num(totalMatch.group(1)!);

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || _isSkipLine(line)) continue;

    // 메뉴명 수량 금액 (예: 김치찌개 12 108,000)
    var m = RegExp(r'^(.+?)\s+(\d{1,4})\s+([\d,]{3,})$').firstMatch(line);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.length < 2 || RegExp(r'^[\d,.-]+$').hasMatch(name)) continue;
      r.menus.add(ScannedMenuLine(
        name: name,
        qty: _num(m.group(2)!),
        amount: _num(m.group(3)!),
      ));
      continue;
    }
    // 메뉴명 수량 (예: 제육볶음 8)
    m = RegExp(r'^(.+?)\s+(\d{1,4})$').firstMatch(line);
    if (m != null) {
      final name = m.group(1)!.trim();
      final qty = _num(m.group(2)!);
      if (name.length < 2 ||
          qty > 500 ||
          RegExp(r'^[\d,.-]+$').hasMatch(name)) {
        continue;
      }
      r.menus.add(ScannedMenuLine(name: name, qty: qty));
    }
  }

  if (r.total == 0) {
    r.total = r.menus.fold(0.0, (s, m) => s + m.amount);
  }
  return r;
}

/// 사업자등록증 파싱
ScannedBizCert parseBizCertText(String text) {
  final r = ScannedBizCert();

  // 사업자등록번호: 000-00-00000
  final biz = RegExp(r'(\d{3})\s*-\s*(\d{2})\s*-\s*(\d{5})').firstMatch(text);
  if (biz != null) {
    r.bizNumber = '${biz.group(1)}-${biz.group(2)}-${biz.group(3)}';
  }

  final lines = text.split('\n').map((l) => l.trim()).toList();
  for (int i = 0; i < lines.length; i++) {
    final l = lines[i];
    String after(String key) {
      final idx = l.indexOf(key);
      var v = l.substring(idx + key.length).replaceAll(RegExp(r'^[:\s]+'), '');
      if (v.isEmpty && i + 1 < lines.length) v = lines[i + 1].trim();
      return v;
    }

    if (l.contains('상호') && r.storeName.isEmpty) {
      r.storeName = after('상호').replaceAll(RegExp(r'[():]'), '').trim();
    }
    if ((l.contains('성명') || l.contains('대표자')) && r.ownerName.isEmpty) {
      final v = after(l.contains('대표자') ? '대표자' : '성명');
      r.ownerName = v.replaceAll(RegExp(r'[():]'), '').trim();
    }
    if ((l.contains('사업장 소재지') ||
            l.contains('사업장소재지') ||
            l.contains('소재지')) &&
        r.address.isEmpty) {
      r.address = after('소재지');
    }
  }
  return r;
}

/// 메뉴판 파싱: "메뉴명 가격" 줄 인식
List<ScannedItem> parseMenuBoardText(String text) {
  final results = <ScannedItem>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || _isSkipLine(line)) continue;
    // 김치찌개 9,000 / 김치찌개 9000원 / 김치찌개....9,000
    final m = RegExp(r'^(.+?)[\s.·]+([\d,]{4,})\s*원?$').firstMatch(line);
    if (m != null) {
      final name = m.group(1)!.trim().replaceAll(RegExp(r'[.·]+$'), '');
      if (name.length < 2 || RegExp(r'^[\d,.-]+$').hasMatch(name)) continue;
      final price = _num(m.group(2)!);
      if (price < 500 || price > 500000) continue;
      results.add(ScannedItem(name: name, price: price));
    }
  }
  return results;
}
