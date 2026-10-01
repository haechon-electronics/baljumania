import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../scan_parsers.dart';
import '../scan_service.dart';
import '../theme.dart';
import '../widgets/ad_banner.dart';
import 'scan_screen.dart';

/// 스마트 스캔: 찍기만 하면 문서 종류를 자동 판별해서 맞는 기능으로 연결
class SmartScanScreen extends StatefulWidget {
  const SmartScanScreen({super.key});

  @override
  State<SmartScanScreen> createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends State<SmartScanScreen> {
  bool _scanning = false;
  String? _lastFail;

  // 마지막 촬영본 보관 → 판별 틀려도 재촬영 없이 다른 종류로 열 수 있게
  XFile? _lastImage;
  String _lastOcr = '';

  Future<void> _scan({required bool fromCamera}) async {
    final svc = ScanService.instance;
    final img = await svc.pickImage(fromCamera: fromCamera);
    if (img == null) return;

    setState(() {
      _scanning = true;
      _lastFail = null;
    });

    try {
      String docType = 'unknown';
      Map<String, dynamic>? geminiData;
      String ocr = '';
      String? imageB64;
      _lastImage = img;
      _lastOcr = '';

      // 1차: Gemini 통합 판별 (키 있으면 판별+추출 한 번에)
      final auto = await svc.analyzeWithGemini(img, 'auto');
      if (auto != null) {
        docType = auto['docType'] as String? ?? 'unknown';
        final data = auto['data'];
        if (data is Map) {
          geminiData = Map<String, dynamic>.from(data);
        }
      } else {
        // 2차: ML Kit 무료 OCR + 키워드 판별
        ocr = await svc.recognizeText(img);
        _lastOcr = ocr;
        if (ocr.trim().isEmpty) {
          setState(() {
            _scanning = false;
            _lastFail = '${svc.failMessage()}\n\n'
                '· 문서가 화면에 꽉 차게, 초점을 맞춰서 찍어주세요\n'
                '· 그림자 없이 밝은 곳에서 찍으면 더 잘 읽혀요';
          });
          return;
        }
        docType = classifyDocument(ocr);
      }

      if (docType == 'bizCert') {
        final bytes = await img.readAsBytes();
        imageB64 = base64Encode(bytes);
      }

      if (!mounted) return;
      setState(() => _scanning = false);

      switch (docType) {
        case 'receipt':
          _confirmAndGo(
            '영수증 · 구매내역',
            Icons.receipt_long,
            '구매기록 + 재고에 반영할게요',
            ReceiptScanScreen(
                preloadedOcr: ocr.isEmpty ? null : ocr,
                preloadedGemini: geminiData),
          );
          break;
        case 'salesReport':
          _confirmAndGo(
            '포스 매출일보',
            Icons.point_of_sale,
            '메뉴별 판매로 입력하고 재고를 차감할게요',
            SalesReportScanScreen(
                preloadedOcr: ocr.isEmpty ? null : ocr,
                preloadedGemini: geminiData),
          );
          break;
        case 'bizCert':
          _confirmAndGo(
            '사업자등록증',
            Icons.badge,
            '서류지갑에 정보와 사진을 저장할게요',
            BizCertScanScreen(
                preloadedOcr: ocr.isEmpty ? null : ocr,
                preloadedGemini: geminiData,
                preloadedImageB64: imageB64),
          );
          break;
        case 'menu':
          _confirmAndGo(
            '메뉴판',
            Icons.menu_book,
            '메뉴와 가격을 자동 등록할게요',
            MenuBoardScanScreen(
                preloadedOcr: ocr.isEmpty ? null : ocr,
                preloadedGemini: geminiData),
          );
          break;
        case 'buyList':
          _confirmAndGo(
            '구매 메모 (장보기 리스트)',
            Icons.edit_note_rounded,
            '적으신 품목을 발주 리스트로 만들어드려요',
            BuyListScanScreen(
                preloadedOcr: ocr.isEmpty ? null : ocr,
                preloadedGemini: geminiData),
          );
          break;
        default:
          // 판별 실패 → 찍은 사진 그대로 종류만 고르게
          _chooseTypeAndGo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _lastFail = '인식 중 문제가 생겼어요. 다시 시도해 주세요.';
        });
      }
    }
  }

  void _confirmAndGo(
      String typeName, IconData icon, String action, Widget screen) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('이 사진은 [$typeName] 같아요!',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(action,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('맞아요, 계속하기'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => screen));
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // 재촬영 없이 같은 사진으로 종류만 다시 선택
                  _chooseTypeAndGo();
                },
                child: const Text('아니에요, 다른 종류예요'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 판별 실패/오판 시: 이미 찍은 사진으로 문서 종류만 골라서 진행
  void _chooseTypeAndGo() {
    if (_lastImage == null) {
      setState(() =>
          _lastFail = '아래에서 문서 종류를 직접 선택해 주세요.');
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text('방금 찍은 사진, 어떤 문서인가요?',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 4),
                child: Text('다시 찍지 않아도 돼요. 종류만 골라주세요!',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              _typePick(ctx, Icons.receipt_long, '영수증 · 구매내역', 'receipt'),
              _typePick(ctx, Icons.point_of_sale, '포스 매출일보', 'salesReport'),
              _typePick(ctx, Icons.badge, '사업자등록증', 'bizCert'),
              _typePick(ctx, Icons.menu_book, '메뉴판', 'menu'),
              _typePick(ctx, Icons.edit_note_rounded, '구매 메모 → 발주 만들기', 'buyList'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePick(
      BuildContext ctx, IconData icon, String title, String task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 28),
        title: Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(ctx);
          _openWithType(task);
        },
      ),
    );
  }

  Future<void> _openWithType(String task) async {
    final img = _lastImage;
    if (img == null) return;

    setState(() {
      _scanning = true;
      _lastFail = null;
    });

    try {
      final svc = ScanService.instance;
      Map<String, dynamic>? gemini;
      String ocr = _lastOcr;

      // Gemini 있으면 해당 종류 전용 프롬프트로 재분석 (정확도 최고)
      gemini = await svc.analyzeWithGemini(img, task);
      // Gemini 없고 OCR도 없으면 지금 OCR 시도
      if (gemini == null && ocr.trim().isEmpty) {
        ocr = await svc.recognizeText(img);
        _lastOcr = ocr;
      }

      String? imageB64;
      if (task == 'bizCert') {
        final bytes = await img.readAsBytes();
        imageB64 = base64Encode(bytes);
      }

      if (!mounted) return;
      setState(() => _scanning = false);

      final Widget screen;
      switch (task) {
        case 'receipt':
          screen = ReceiptScanScreen(
              preloadedOcr: ocr.isEmpty ? null : ocr,
              preloadedGemini: gemini);
          break;
        case 'salesReport':
          screen = SalesReportScanScreen(
              preloadedOcr: ocr.isEmpty ? null : ocr,
              preloadedGemini: gemini);
          break;
        case 'bizCert':
          screen = BizCertScanScreen(
              preloadedOcr: ocr.isEmpty ? null : ocr,
              preloadedGemini: gemini,
              preloadedImageB64: imageB64);
          break;
        case 'buyList':
          screen = BuyListScanScreen(
              preloadedOcr: ocr.isEmpty ? null : ocr,
              preloadedGemini: gemini);
          break;
        default:
          screen = MenuBoardScanScreen(
              preloadedOcr: ocr.isEmpty ? null : ocr,
              preloadedGemini: gemini);
      }
      if (!mounted) return;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => screen));
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _lastFail = '분석 중 문제가 생겼어요. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AI 정밀인식은 키 내장으로 항상 켜짐 (무제한)
    context.select<AppState, bool>((a) => a.geminiApiKey.isNotEmpty);
    final svc = ScanService.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('스마트 촬영')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 40, color: AppColors.primary),
                const SizedBox(height: 10),
                const Text(
                  '그냥 찍기만 하세요!',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '영수증, 매출일보, 손글씨 구매 메모까지\n제가 알아서 판별하고 입력해드려요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  svc.hasUserKey
                      ? '(AI 정밀인식 · 본인 키 사용 중)'
                      : '(AI 정밀인식 켜짐 · 무제한 무료)',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_scanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('문서를 분석하는 중...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: () => _scan(fromCamera: true),
                icon: const Icon(Icons.photo_camera, size: 30),
                label: const Text('촬영하기',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _scan(fromCamera: false),
              icon: const Icon(Icons.photo_library),
              label: const Text('사진첩에서 선택'),
            ),
          ],
          if (_lastFail != null) ...[
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFFFF3E0),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_lastFail!,
                        style:
                            const TextStyle(fontSize: 15, height: 1.5)),
                    if (_lastImage != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.touch_app, size: 20),
                        label: const Text('방금 사진으로 종류 직접 선택'),
                        onPressed: _chooseTypeAndGo,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('직접 선택해서 촬영',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          _manualTile(Icons.receipt_long, '영수증 · 거래명세서',
              const ReceiptScanScreen()),
          _manualTile(Icons.point_of_sale, '포스 일일매출 (일보)',
              const SalesReportScanScreen()),
          _manualTile(
              Icons.badge, '사업자등록증', const BizCertScanScreen()),
          _manualTile(
              Icons.menu_book, '메뉴판', const MenuBoardScanScreen()),
          _manualTile(Icons.edit_note_rounded, '구매 메모 → 발주 만들기',
              const BuyListScanScreen()),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }

  Widget _manualTile(IconData icon, String title, Widget screen) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
