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
