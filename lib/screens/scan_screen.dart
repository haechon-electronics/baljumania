import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../models2.dart';
import '../scan_parsers.dart';
import '../scan_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/ad_banner.dart';
import 'order_edit_screen.dart';

/// 촬영 인식 허브: 4가지 스캔 기능 입구
class ScanHubScreen extends StatelessWidget {
  const ScanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ai = ScanService.instance.aiEnabled;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('사진 촬영 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ai ? AppColors.primarySoft : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(ai ? Icons.auto_awesome : Icons.info_outline,
                    color: ai ? AppColors.primary : AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ai
                        ? (ScanService.instance.hasUserKey
                            ? 'AI 정밀인식 켜짐 (본인 키 · 무제한) — 구겨진 영수증·손글씨도 인식돼요!'
                            : 'AI 정밀인식 켜짐 — 오늘 무료 인식 ${ScanService.instance.freeRemainingToday}회 남았어요 (매일 초기화)')
                        : '오늘 무료 AI 인식을 모두 썼어요. 기본인식으로 계속 쓰거나,\n[더보기 → AI 정밀인식 설정]에 본인 키를 넣으면 무제한이에요.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(
            context,
            icon: Icons.receipt_long,
            title: '영수증 · 거래명세서',
            subtitle: '마트/거래처 영수증 → 구매기록 + 재고 자동 반영',
            screen: const ReceiptScanScreen(),
          ),
          _tile(
            context,
            icon: Icons.point_of_sale,
            title: '포스 일일매출 (일보)',
            subtitle: '포스 화면/일보 촬영 → 메뉴별 판매 자동 입력',
            screen: const SalesReportScanScreen(),
          ),
          _tile(
            context,
            icon: Icons.badge,
            title: '사업자등록증',
            subtitle: '촬영하면 사업자번호·상호·주소 자동 입력 + 보관',
            screen: const BizCertScanScreen(),
          ),
          _tile(
            context,
            icon: Icons.menu_book,
            title: '메뉴판',
            subtitle: '메뉴판 촬영 → 메뉴·가격 자동 등록',
            screen: const MenuBoardScanScreen(),
          ),
          _tile(
            context,
            icon: Icons.edit_note_rounded,
            title: '구매 메모 → 발주 만들기',
            subtitle: '손글씨 장보기 메모 촬영 → 발주 리스트 자동 생성',
            screen: const BuyListScanScreen(),
          ),
          const SizedBox(height: 12),
          if (kIsWeb)
            const Card(
              color: Color(0xFFFFF3E0),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  '⚠️ 웹 미리보기에서는 무료인식(ML Kit)이 동작하지 않아요.\n폰에 설치(APK)하면 촬영 인식이 전부 작동합니다!\n(AI 정밀인식 키가 있으면 웹에서도 인식 가능)',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),
          Text(
            app.storeName.isEmpty
                ? ''
                : '💡 인식 결과는 저장 전에 항상 확인·수정할 수 있어요.',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Widget screen}) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primary, size: 26),
        ),
        title: Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.photo_camera, color: AppColors.primary),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}

/// ── 공통: 촬영/선택 버튼 + 인식 진행 ──
mixin _ScanFlow<T extends StatefulWidget> on State<T> {
  bool scanning = false;

  Future<(XFile, String, Map<String, dynamic>?)?> capture(
      String task) async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_camera, color: AppColors.primary),
              title: const Text('카메라로 촬영', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('사진첩에서 선택', style: TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final img =
        await ScanService.instance.pickImage(fromCamera: source);
    if (img == null) return null;

    setState(() => scanning = true);
    try {
      // 1차: Gemini (키 있으면)
      final gemini =
          await ScanService.instance.analyzeWithGemini(img, task);
      // 2차: ML Kit 무료 OCR
      String ocr = '';
      if (gemini == null) {
        ocr = await ScanService.instance.recognizeText(img);
      }
      return (img, ocr, gemini);
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Widget scanButton(String label, VoidCallback onTap) {
    return scanning
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('인식 중입니다...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.photo_camera),
            label: Text(label),
          );
  }

  void toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// ── 1. 영수증 스캔 ──
class ReceiptScanScreen extends StatefulWidget {
  final String? preloadedOcr;
  final Map<String, dynamic>? preloadedGemini;
  const ReceiptScanScreen(
      {super.key, this.preloadedOcr, this.preloadedGemini});
  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen>
    with _ScanFlow {
  ScannedReceipt? _result;
  String _category = '식자재';
  bool _updateStock = true;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedOcr != null || widget.preloadedGemini != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apply(widget.preloadedOcr ?? '', widget.preloadedGemini);
      });
    }
  }

  Future<void> _scan() async {
    final res = await capture('receipt');
    if (res == null) return;
    final (_, ocr, gemini) = res;
    _apply(ocr, gemini);
  }

  void _apply(String ocr, Map<String, dynamic>? gemini) {
    ScannedReceipt r;
    if (gemini != null) {
      r = ScannedReceipt()
        ..store = gemini['store'] as String? ?? ''
        ..date = gemini['date'] as String? ?? ''
        ..total = (gemini['total'] as num?)?.toDouble() ?? 0
        ..items = ((gemini['items'] as List?) ?? [])
            .map((e) => ScannedItem(
                  name: e['name'] as String? ?? '',
                  qty: (e['qty'] as num?)?.toDouble() ?? 1,
                  unit: e['unit'] as String? ?? '개',
                  price: (e['price'] as num?)?.toDouble() ?? 0,
                ))
            .where((i) => i.name.isNotEmpty)
            .toList();
    } else if (ocr.isNotEmpty) {
      r = parseReceiptText(ocr);
    } else {
      toast('글자를 인식하지 못했어요. 다시 찍어주세요. (웹에서는 AI 키 필요)');
      return;
    }
    if (r.date.isEmpty) r.date = todayIso();
    setState(() => _result = r);
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null || r.items.isEmpty) return;
    final app = context.read<AppState>();

    // 간편 구매 기록
    final itemsText = r.items
        .map((i) => '${i.name} ${formatQty(i.qty)}${i.unit}')
        .join(', ');
    final amount = r.total > 0
        ? r.total
        : r.items.fold(0.0, (s, i) => s + i.price * i.qty);
    await app.savePurchase(SimplePurchase(
      id: '',
      date: r.date,
      source: r.store.isEmpty ? '영수증 인식' : r.store,
      itemsText: itemsText,
      amount: amount,
      category: _category,
    ));

    // 재고 반영 (이름 매칭되는 품목만 수량 증가)
    int matched = 0;
    if (_updateStock) {
      for (final si in r.items) {
        final stockMatches = app.stockItems.where((s) =>
            s.name.replaceAll(' ', '') == si.name.replaceAll(' ', ''));
        if (stockMatches.isNotEmpty) {
          final stock = stockMatches.first;
          stock.quantity += si.qty;
          if (si.price > 0) {
            final unitPrice = si.qty > 0 ? si.price : si.price;
            if (unitPrice != stock.lastPrice) {
              stock.prevPrice = stock.lastPrice;
              stock.lastPrice = unitPrice;
            }
          }
          await app.saveStockItem(stock);
          matched++;
        }
      }
    }

    if (mounted) {
      toast('저장 완료! 구매기록 등록${_updateStock ? ' + 재고 $matched개 품목 반영' : ''}');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('영수증 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          scanButton(r == null ? '영수증 촬영하기' : '다시 촬영하기', _scan),
          const SizedBox(height: 16),
          if (r != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.store.isEmpty ? '(매장명 미인식)' : r.store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(formatDateKr(r.date),
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                    const Divider(),
                    ...r.items.asMap().entries.map((e) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${e.value.name}  ${formatQty(e.value.qty)}${e.value.unit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                                e.value.price > 0
                                    ? formatWon(e.value.price)
                                    : '-',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(
                                  () => r.items.removeAt(e.key)),
                            ),
                          ],
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('합계',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text(formatWon(r.total),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('분류:', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: kStockCategories
                        .map((c) => ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                  color: _category == c
                                      ? Colors.white
                                      : Colors.black87),
                              onSelected: (_) =>
                                  setState(() => _category = c),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('재고에도 자동 반영 (이름이 같은 품목)',
                  style: TextStyle(fontSize: 16)),
              value: _updateStock,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _updateStock = v),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: r.items.isEmpty ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('이대로 저장'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }
}

/// ── 2. 포스 일보 스캔 ──
class SalesReportScanScreen extends StatefulWidget {
  final String? preloadedOcr;
  final Map<String, dynamic>? preloadedGemini;
  const SalesReportScanScreen(
      {super.key, this.preloadedOcr, this.preloadedGemini});
  @override
  State<SalesReportScanScreen> createState() =>
      _SalesReportScanScreenState();
}

class _SalesReportScanScreenState extends State<SalesReportScanScreen>
    with _ScanFlow {
  ScannedSalesReport? _result;
  String _channel = '홀';

  @override
  void initState() {
    super.initState();
    if (widget.preloadedOcr != null || widget.preloadedGemini != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apply(widget.preloadedOcr ?? '', widget.preloadedGemini);
      });
    }
  }

  Future<void> _scan() async {
    final res = await capture('salesReport');
    if (res == null) return;
    final (_, ocr, gemini) = res;
    _apply(ocr, gemini);
  }

  void _apply(String ocr, Map<String, dynamic>? gemini) {
    ScannedSalesReport r;
    if (gemini != null) {
      r = ScannedSalesReport()
        ..date = gemini['date'] as String? ?? ''
        ..total = (gemini['total'] as num?)?.toDouble() ?? 0
        ..menus = ((gemini['menus'] as List?) ?? [])
            .map((e) => ScannedMenuLine(
                  name: e['name'] as String? ?? '',
                  qty: (e['qty'] as num?)?.toDouble() ?? 0,
                  amount: (e['amount'] as num?)?.toDouble() ?? 0,
                ))
            .where((m) => m.name.isNotEmpty)
            .toList();
    } else if (ocr.isNotEmpty) {
      r = parseSalesReportText(ocr);
    } else {
      toast('글자를 인식하지 못했어요. 다시 찍어주세요. (웹에서는 AI 키 필요)');
      return;
    }
    if (r.date.isEmpty) r.date = todayIso();
    setState(() => _result = r);
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null) return;
    final app = context.read<AppState>();

    // 메뉴 이름 매칭 → menuSales / 미매칭은 extraAmount
    final menuSales = <String, double>{};
    double extra = 0;
    int matched = 0;
    for (final line in r.menus) {
      final m = app.menus.where((menu) =>
          menu.name.replaceAll(' ', '') ==
          line.name.replaceAll(' ', ''));
      if (m.isNotEmpty && line.qty > 0) {
        menuSales[m.first.id] =
            (menuSales[m.first.id] ?? 0) + line.qty;
        matched++;
      } else {
        extra += line.amount;
      }
    }
    // 총액이 있고 메뉴 합산이 부족하면 차액 보정
    if (r.total > 0) {
      double menuAmount = 0;
      menuSales.forEach((id, qty) {
        final ms = app.menus.where((m) => m.id == id);
        if (ms.isNotEmpty) menuAmount += ms.first.price * qty;
      });
      final diff = r.total - menuAmount - extra;
      if (diff > 0) extra += diff;
    }

    await app.saveSale(SaleRecord(
      id: '',
      date: r.date,
      channel: _channel,
      menuSales: menuSales,
      extraAmount: extra,
      weather: '',
    ));

    if (mounted) {
      toast('판매 저장 완료! 메뉴 $matched개 매칭, 재고 자동 차감됨');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('포스 일보 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          scanButton(r == null ? '일보/포스 화면 촬영하기' : '다시 촬영하기', _scan),
          const SizedBox(height: 16),
          if (r != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('날짜: ${formatDateKr(r.date)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...r.menus.asMap().entries.map((e) {
                      final isMatched = app.menus.any((m) =>
                          m.name.replaceAll(' ', '') ==
                          e.value.name.replaceAll(' ', ''));
                      return Row(
                        children: [
                          Icon(
                            isMatched
                                ? Icons.check_circle
                                : Icons.help_outline,
                            size: 20,
                            color: isMatched
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${e.value.name} × ${formatQty(e.value.qty)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (e.value.amount > 0)
                            Text(formatWon(e.value.amount),
                                style: const TextStyle(fontSize: 15)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                setState(() => r.menus.removeAt(e.key)),
                          ),
                        ],
                      );
                    }),
                    const Divider(),
                    Text('총매출: ${formatWon(r.total)}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 4),
                    const Text(
                      '✅ = 등록된 메뉴와 매칭 (재고 자동 차감)\n❓ = 미등록 메뉴 (금액만 합산)',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['홀', '배민', '쿠팡이츠', '요기요', '기타']
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _channel == c,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: _channel == c
                                ? Colors.white
                                : Colors.black87),
                        onSelected: (_) => setState(() => _channel = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('판매로 저장 (재고 자동 차감)'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }
}

/// ── 3. 사업자등록증 스캔 ──
class BizCertScanScreen extends StatefulWidget {
  final String? preloadedOcr;
  final Map<String, dynamic>? preloadedGemini;
  final String? preloadedImageB64;
  const BizCertScanScreen(
      {super.key,
      this.preloadedOcr,
      this.preloadedGemini,
      this.preloadedImageB64});
  @override
  State<BizCertScanScreen> createState() => _BizCertScanScreenState();
}

class _BizCertScanScreenState extends State<BizCertScanScreen>
    with _ScanFlow {
  final _bizC = TextEditingController();
  final _nameC = TextEditingController();
  final _ownerC = TextEditingController();
  final _addrC = TextEditingController();
  String? _imageB64;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedOcr != null || widget.preloadedGemini != null) {
      _imageB64 = widget.preloadedImageB64;
      _applyResult(widget.preloadedOcr ?? '', widget.preloadedGemini);
      _scanned = true;
    }
  }

  @override
  void dispose() {
    _bizC.dispose();
    _nameC.dispose();
    _ownerC.dispose();
    _addrC.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final res = await capture('bizCert');
    if (res == null) return;
    final (img, ocr, gemini) = res;

    final bytes = await img.readAsBytes();
    _imageB64 = base64Encode(bytes);
    _applyResult(ocr, gemini);
    setState(() => _scanned = true);
  }

  void _applyResult(String ocr, Map<String, dynamic>? gemini) {
    if (gemini != null) {
      _bizC.text = gemini['bizNumber'] as String? ?? '';
      _nameC.text = gemini['storeName'] as String? ?? '';
      _ownerC.text = gemini['ownerName'] as String? ?? '';
      _addrC.text = gemini['address'] as String? ?? '';
    } else if (ocr.isNotEmpty) {
      final r = parseBizCertText(ocr);
      _bizC.text = r.bizNumber;
      _nameC.text = r.storeName;
      _ownerC.text = r.ownerName;
      _addrC.text = r.address;
    }
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final info = app.storeInfo;
    if (_bizC.text.trim().isNotEmpty) info.bizNumber = _bizC.text.trim();
    if (_nameC.text.trim().isNotEmpty) info.storeName = _nameC.text.trim();
    if (_ownerC.text.trim().isNotEmpty) {
      info.ownerName = _ownerC.text.trim();
    }
    if (_addrC.text.trim().isNotEmpty) info.address = _addrC.text.trim();
    if (_imageB64 != null) info.bizCertImage = _imageB64;
    await app.saveStoreInfo(info);
    if (mounted) {
      toast('서류지갑에 저장 완료!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('사업자등록증 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          scanButton(_scanned ? '다시 촬영하기' : '사업자등록증 촬영하기', _scan),
          const SizedBox(height: 16),
          if (_scanned) ...[
            _field(_bizC, '사업자등록번호'),
            _field(_nameC, '상호'),
            _field(_ownerC, '대표자'),
            _field(_addrC, '사업장 주소'),
            const SizedBox(height: 8),
            const Text('※ 인식 결과를 확인하고 틀린 부분은 고쳐주세요.\n사진도 서류지갑에 함께 보관됩니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('서류지갑에 저장'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(labelText: label),
        ),
      );
}

/// ── 4. 메뉴판 스캔 ──
class MenuBoardScanScreen extends StatefulWidget {
  final String? preloadedOcr;
  final Map<String, dynamic>? preloadedGemini;
  const MenuBoardScanScreen(
      {super.key, this.preloadedOcr, this.preloadedGemini});
  @override
  State<MenuBoardScanScreen> createState() => _MenuBoardScanScreenState();
}

class _MenuBoardScanScreenState extends State<MenuBoardScanScreen>
    with _ScanFlow {
  List<ScannedItem>? _menus;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedOcr != null || widget.preloadedGemini != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apply(widget.preloadedOcr ?? '', widget.preloadedGemini);
      });
    }
  }

  Future<void> _scan() async {
    final res = await capture('menu');
    if (res == null) return;
    final (_, ocr, gemini) = res;
    _apply(ocr, gemini);
  }

  void _apply(String ocr, Map<String, dynamic>? gemini) {
    List<ScannedItem> menus;
    if (gemini != null) {
      menus = ((gemini['menus'] as List?) ?? [])
          .map((e) => ScannedItem(
                name: e['name'] as String? ?? '',
                price: (e['price'] as num?)?.toDouble() ?? 0,
              ))
          .where((m) => m.name.isNotEmpty)
          .toList();
    } else if (ocr.isNotEmpty) {
      menus = parseMenuBoardText(ocr);
    } else {
      toast('글자를 인식하지 못했어요. 다시 찍어주세요. (웹에서는 AI 키 필요)');
      return;
    }
    if (menus.isEmpty) {
      toast('메뉴를 찾지 못했어요. "메뉴명 + 가격"이 잘 보이게 찍어주세요.');
      return;
    }
    setState(() => _menus = menus);
  }

  Future<void> _save() async {
    final menus = _menus;
    if (menus == null || menus.isEmpty) return;
    final app = context.read<AppState>();
    int added = 0;
    for (final m in menus) {
      final exists = app.menus.any((x) =>
          x.name.replaceAll(' ', '') == m.name.replaceAll(' ', ''));
      if (exists) continue;
      await app.saveMenu(
          MenuModel(id: '', name: m.name, price: m.price));
      added++;
    }
    if (mounted) {
      toast('메뉴 $added개 등록 완료! (레시피는 메뉴에서 추가하세요)');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menus = _menus;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('메뉴판 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          scanButton(menus == null ? '메뉴판 촬영하기' : '다시 촬영하기', _scan),
          const SizedBox(height: 16),
          if (menus != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ...menus.asMap().entries.map((e) => Row(
                          children: [
                            Expanded(
                                child: Text(e.value.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(fontSize: 17))),
                            Text(formatWon(e.value.price),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(
                                  () => menus.removeAt(e.key)),
                            ),
                          ],
                        )),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: Text('메뉴 ${menus.length}개 등록하기'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }
}

/// ── 5. 구매 메모(장보기 리스트) 스캔 → 발주 리스트로 ──
class BuyListScanScreen extends StatefulWidget {
  final String? preloadedOcr;
  final Map<String, dynamic>? preloadedGemini;
  const BuyListScanScreen(
      {super.key, this.preloadedOcr, this.preloadedGemini});
  @override
  State<BuyListScanScreen> createState() => _BuyListScanScreenState();
}

class _BuyListScanScreenState extends State<BuyListScanScreen>
    with _ScanFlow {
  List<ScannedBuyItem>? _items;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedOcr != null || widget.preloadedGemini != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apply(widget.preloadedOcr ?? '', widget.preloadedGemini);
      });
    }
  }

  Future<void> _scan() async {
    final res = await capture('buyList');
    if (res == null) return;
    final (_, ocr, gemini) = res;
    _apply(ocr, gemini);
  }

  void _apply(String ocr, Map<String, dynamic>? gemini) {
    List<ScannedBuyItem> items;
    if (gemini != null) {
      items = ((gemini['items'] as List?) ?? [])
          .map((e) => ScannedBuyItem(
                name: e['name'] as String? ?? '',
                qty: (e['qty'] as num?)?.toDouble() ?? 1,
                unit: e['unit'] as String? ?? '개',
              ))
          .where((i) => i.name.isNotEmpty)
          .toList();
    } else if (ocr.isNotEmpty) {
      items = parseBuyListText(ocr);
    } else {
      toast('글자를 인식하지 못했어요. 다시 찍어주세요. (웹에서는 AI 키 필요)');
      return;
    }
    if (items.isEmpty) {
      toast('품목을 찾지 못했어요. 한 줄에 하나씩 적힌 메모가 잘 보이게 찍어주세요.');
      return;
    }
    setState(() => _items = items);
  }

  /// 인식된 품목들 → 발주 품목(OrderLine)으로 변환해서 새 발주 화면으로
  void _goToOrder() {
    final items = _items;
    if (items == null || items.isEmpty) return;
    final app = context.read<AppState>();

    final lines = <OrderLine>[];
    String? supplierId;
    for (final it in items) {
      // 재고에 같은 이름 품목이 있으면 단가/단위/거래처 자동 연결
      final matches = app.stockItems.where((s) =>
          s.name.replaceAll(' ', '') == it.name.replaceAll(' ', ''));
      if (matches.isNotEmpty) {
        final stock = matches.first;
        lines.add(OrderLine(
          itemId: stock.id,
          itemName: stock.name,
          qty: it.qty,
          unit: it.unit == '개' && stock.unit.isNotEmpty
              ? stock.unit
              : it.unit,
          price: stock.lastPrice,
        ));
        if (supplierId == null && stock.supplierId.isNotEmpty) {
          supplierId = stock.supplierId;
        }
      } else {
        // 재고에 없는 품목도 그대로 발주 줄에 추가 (단가 0)
        lines.add(OrderLine(
          itemId: '',
          itemName: it.name,
          qty: it.qty,
          unit: it.unit,
        ));
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderEditScreen(
            prefillLines: lines, prefillSupplierId: supplierId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final app = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('구매 메모 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (items == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '손으로 쓴 장보기 메모, 포스트잇, 칠판 메모를 찍으면\n'
                '품목을 읽어서 발주 리스트로 바로 만들어드려요!\n'
                '예) "양파 2망, 두부 5모, 계란 1판"',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          scanButton(items == null ? '메모 촬영하기' : '다시 촬영하기', _scan),
          const SizedBox(height: 16),
          if (items != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('인식된 품목 ${items.length}개',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    const Divider(),
                    ...items.asMap().entries.map((e) {
                      final inStock = app.stockItems.any((s) =>
                          s.name.replaceAll(' ', '') ==
                          e.value.name.replaceAll(' ', ''));
                      return Row(
                        children: [
                          Icon(
                            inStock
                                ? Icons.link_rounded
                                : Icons.fiber_new_rounded,
                            size: 20,
                            color: inStock
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${e.value.name}  ${formatQty(e.value.qty)}${e.value.unit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(
                                () => items.removeAt(e.key)),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    const Text(
                      '🔗 = 재고에 있는 품목 (단가·거래처 자동 연결)\n'
                      '🆕 = 새 품목 (발주서에 이름 그대로 추가)',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: items.isEmpty ? null : _goToOrder,
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: Text('이 ${items.length}개로 발주 만들기'),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }
}
