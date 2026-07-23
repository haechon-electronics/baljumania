import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../payroll.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/ad_banner.dart';

/// 세무자료 내보내기: 매입장/매출장/급여대장/월간요약 CSV 생성 → 세무사에게 공유
class TaxExportScreen extends StatefulWidget {
  const TaxExportScreen({super.key});

  @override
  State<TaxExportScreen> createState() => _TaxExportScreenState();
}

class _TaxExportScreenState extends State<TaxExportScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String get _ym =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('세무자료 내보내기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '한 달 자료를 엑셀(CSV) 표로 만들어\n세무사님께 카톡/문자로 바로 보낼 수 있어요.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),

          // 월 선택
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: () => setState(() =>
                        _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  Text(
                    '${_month.year}년 ${_month.month}월',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: () => setState(() =>
                        _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _exportTile(
            icon: Icons.shopping_cart,
            title: '매입장',
            subtitle: '발주 입고 내역 + 간편 구매 내역',
            onTap: () => _export('매입장', _buildPurchaseLedger(app)),
          ),
          _exportTile(
            icon: Icons.point_of_sale,
            title: '매출장',
            subtitle: '일자별·채널별 매출 내역',
            onTap: () => _export('매출장', _buildSalesLedger(app)),
          ),
          _exportTile(
            icon: Icons.groups,
            title: '급여대장',
            subtitle: '직원별 근무시간·급여·공제 내역',
            onTap: () => _export('급여대장', _buildPayrollLedger(app)),
          ),
          _exportTile(
            icon: Icons.summarize,
            title: '월간 요약',
            subtitle: '매출·매입·인건비·원가율 한 장 요약',
            onTap: () => _export('월간요약', _buildSummary(app)),
          ),
          const SizedBox(height: 12),
          const Text(
            '※ CSV 파일은 엑셀에서 바로 열 수 있습니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: AdBanner()),
    );
  }

  Widget _exportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.ios_share, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }

  // ── CSV 생성 로직 ──

  String _csvCell(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  String _rows(List<List<String>> rows) =>
      rows.map((r) => r.map(_csvCell).join(',')).join('\n');

  String _buildPurchaseLedger(AppState app) {
    final rows = <List<String>>[
      ['날짜', '구분', '거래처/구매처', '품목', '금액'],
    ];
    // 발주 입고분
    for (final o in app.orders) {
      if (!o.orderDate.startsWith(_ym)) continue;
      final items = o.lines
          .map((l) => '${l.itemName} ${formatQty(l.qty)}${l.unit}')
          .join(' / ');
      rows.add([
        o.orderDate,
        '발주',
        o.supplierName,
        items,
        o.totalAmount.round().toString(),
      ]);
    }
    // 간편 구매분
    for (final p in app.purchases) {
      if (!p.date.startsWith(_ym)) continue;
      rows.add([
        p.date,
        '간편구매(${p.category})',
        p.source,
        p.itemsText,
        p.amount.round().toString(),
      ]);
    }
    final total = app.monthlyPurchaseTotal(_ym);
    rows.add([]);
    rows.add(['합계', '', '', '', total.round().toString()]);
    return _rows(rows);
  }

  String _buildSalesLedger(AppState app) {
    final rows = <List<String>>[
      ['날짜', '채널', '날씨', '메뉴 내역', '매출액'],
    ];
    final monthSales = app.sales.where((s) => s.date.startsWith(_ym)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final s in monthSales) {
      final menuText = s.menuSales.entries.map((e) {
        final menu = app.menus.where((m) => m.id == e.key).toList();
        final name = menu.isEmpty ? '알수없음' : menu.first.name;
        return '$name ${formatQty(e.value)}개';
      }).join(' / ');
      rows.add([
        s.date,
        s.channel,
        s.weather,
        menuText.isEmpty ? '(총액 입력)' : menuText,
        app.saleAmount(s).round().toString(),
      ]);
    }
    rows.add([]);
    rows.add([
      '합계', '', '', '',
      app.monthlySalesTotal(_ym).round().toString(),
    ]);
    return _rows(rows);
  }

  String _buildPayrollLedger(AppState app) {
    final rows = <List<String>>[
      ['직원명', '고용형태', '근무시간', '기본급', '주휴수당', '공제합계', '실지급액', '비고'],
    ];
    double totalNet = 0;
    for (final e in app.employees) {
      final logs = app.workLogs
          .where((l) => l.employeeId == e.id && l.date.startsWith(_ym))
          .toList();
      final r = calculatePayroll(employee: e, logs: logs);
      totalNet += r.netPay;
      final typeLabel = switch (e.empType) {
        'freelance' => '3.3% 프리랜서',
        'insured' => '4대보험',
        _ => '알바',
      };
      rows.add([
        e.name,
        typeLabel,
        '${r.totalHours.toStringAsFixed(1)}시간',
        r.grossPay.round().toString(),
        r.weeklyHolidayPay.round().toString(),
        r.totalDeduction.round().toString(),
        r.netPay.round().toString(),
        r.note,
      ]);
    }
    rows.add([]);
    rows.add(['실지급 합계', '', '', '', '', '', totalNet.round().toString(), '']);
    return _rows(rows);
  }

  String _buildSummary(AppState app) {
    final salesTotal = app.monthlySalesTotal(_ym);
    final purchaseTotal = app.monthlyPurchaseTotal(_ym);
    double laborTotal = 0;
    for (final e in app.employees) {
      final logs = app.workLogs
          .where((l) => l.employeeId == e.id && l.date.startsWith(_ym))
          .toList();
      laborTotal += calculatePayroll(employee: e, logs: logs).netPay;
    }
    final costRate =
        salesTotal > 0 ? (purchaseTotal / salesTotal * 100) : 0.0;
    final laborRate =
        salesTotal > 0 ? (laborTotal / salesTotal * 100) : 0.0;
    final profit = salesTotal - purchaseTotal - laborTotal;

    // 채널별 매출
    final channelMap = <String, double>{};
    for (final s in app.sales.where((s) => s.date.startsWith(_ym))) {
      channelMap[s.channel] =
          (channelMap[s.channel] ?? 0) + app.saleAmount(s);
    }

    final rows = <List<String>>[
      ['${_month.year}년 ${_month.month}월 요약', ''],
      [],
      ['총 매출', salesTotal.round().toString()],
      ['총 매입(재료비)', purchaseTotal.round().toString()],
      ['인건비(실지급)', laborTotal.round().toString()],
      ['재료 원가율(%)', costRate.toStringAsFixed(1)],
      ['인건비율(%)', laborRate.toStringAsFixed(1)],
      ['대략 이익(매출-매입-인건비)', profit.round().toString()],
      [],
      ['채널별 매출', ''],
    ];
    channelMap.forEach((ch, amt) {
      rows.add([ch, amt.round().toString()]);
    });
    return _rows(rows);
  }

  // ── 공유 ──

  Future<void> _export(String title, String csv) async {
    final app = context.read<AppState>();
    final fileName =
        '${app.storeName}_${title}_$_ym.csv'.replaceAll(' ', '_');
    final header = '[${app.storeName}] ${_month.year}년 ${_month.month}월 $title';

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(header,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_file, color: AppColors.primary),
              title: const Text('CSV 파일로 보내기 (엑셀용)',
                  style: TextStyle(fontSize: 17)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  // UTF-8 BOM 추가 → 한글 엑셀 호환
                  final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
                  final xfile = XFile.fromData(
                    Uint8List.fromList(bytes),
                    name: fileName,
                    mimeType: 'text/csv',
                  );
                  await Share.shareXFiles([xfile], text: header);
                } catch (_) {
                  await Share.share('$header\n\n$csv');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet,
                  color: AppColors.primary),
              title: const Text('텍스트로 보내기 (카톡/문자)',
                  style: TextStyle(fontSize: 17)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share('$header\n\n$csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('복사하기', style: TextStyle(fontSize: 17)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: '$header\n\n$csv'));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복사 완료!')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
