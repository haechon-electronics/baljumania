import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models2.dart';
import '../theme.dart';
import '../utils.dart';

/// 판매 입력 화면 (수동 + 총액)
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sales = app.sales;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('판매 입력')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaleEditScreen()),
        ),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('판매 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: sales.isEmpty
          ? const Center(
              child: Text(
                  '판매 기록이 없습니다.\n마감할 때 오늘 판매량을 입력하세요!\n\n메뉴에 레시피가 등록되어 있으면\n재고가 자동으로 차감됩니다.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 17, color: AppColors.textGrey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              itemCount: sales.length,
              itemBuilder: (context, i) {
                final sale = sales[i];
                final amount = app.saleAmount(sale);
                final menuDesc = sale.menuSales.entries
                    .map((e) {
                      final m = app.menuById(e.key);
                      return m != null
                          ? '${m.name} ${formatQty(e.value)}'
                          : '';
                    })
                    .where((s) => s.isNotEmpty)
                    .join(', ');
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        switch (sale.channel) {
                          '배민' || '쿠팡이츠' || '요기요' =>
                            Icons.delivery_dining_rounded,
                          _ => Icons.storefront_rounded,
                        },
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    title: Text(
                        '${formatDateKr(sale.date)} · ${sale.channel}${sale.weather.isNotEmpty ? ' · ${sale.weather}' : ''}',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    subtitle: menuDesc.isNotEmpty
                        ? Text(menuDesc,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Text(formatWon(amount),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('기록 삭제',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          content: const Text('이 판매 기록을 삭제하시겠습니까?',
                              style: TextStyle(fontSize: 17)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('취소',
                                    style: TextStyle(fontSize: 17))),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제',
                                    style: TextStyle(
                                        fontSize: 17,
                                        color: AppColors.danger))),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<AppState>().deleteSale(sale.id);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// 판매 기록 입력
class SaleEditScreen extends StatefulWidget {
  const SaleEditScreen({super.key});

  @override
  State<SaleEditScreen> createState() => _SaleEditScreenState();
}

class _SaleEditScreenState extends State<SaleEditScreen> {
  DateTime _date = DateTime.now();
  String _channel = '홀';
  String _weather = '';
  final Map<String, double> _menuSales = {};
  final _extraCtrl = TextEditingController();

  static const _channels = ['홀', '배민', '쿠팡이츠', '요기요', '기타'];
  static const _weathers = ['', '맑음', '흐림', '비', '눈', '폭염', '한파'];

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final extra = double.tryParse(_extraCtrl.text) ?? 0;
    if (_menuSales.isEmpty && extra <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('판매 수량이나 매출 금액을 입력해주세요',
              style: TextStyle(fontSize: 16))));
      return;
    }
    final sale = SaleRecord(
      id: '',
      date: _date.toIso8601String().substring(0, 10),
      channel: _channel,
      menuSales: Map.from(_menuSales)..removeWhere((k, v) => v <= 0),
      extraAmount: extra,
      weather: _weather,
    );
    await app.saveSale(sale);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('판매 기록 저장! 레시피 기반으로 재고가 차감되었습니다.',
              style: TextStyle(fontSize: 16))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final menus = app.menus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('판매 기록 입력')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 날짜
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate:
                    DateTime.now().subtract(const Duration(days: 90)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                      formatDateKr(
                          _date.toIso8601String().substring(0, 10)),
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 채널
          const Text('판매 채널',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _channels.map((c) {
              final selected = _channel == c;
              return ChoiceChip(
                label: Text(c,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            selected ? Colors.white : AppColors.textDark)),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                onSelected: (_) => setState(() => _channel = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 날씨
          const Text('오늘 날씨 (매출 분석에 활용)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weathers.where((w) => w.isNotEmpty).map((w) {
              final selected = _weather == w;
              return ChoiceChip(
                label: Text(w,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            selected ? Colors.white : AppColors.textDark)),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                onSelected: (_) =>
                    setState(() => _weather = selected ? '' : w),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 메뉴별 판매량
          const Text('메뉴별 판매 수량',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (menus.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Text(
                  '등록된 메뉴가 없습니다.\n메뉴 & 레시피에서 먼저 메뉴를 등록하거나,\n아래 총 매출액만 입력해도 됩니다.',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textGrey)),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: menus.map((menu) {
                  final qty = _menuSales[menu.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(menu.name,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                              Text(formatWon(menu.price),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                        _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              if (qty > 0) {
                                setState(() =>
                                    _menuSales[menu.id] = qty - 1);
                              }
                            }),
                        SizedBox(
                          width: 52,
                          child: Text(formatQty(qty),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ),
                        _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () => setState(
                                () => _menuSales[menu.id] = qty + 1)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // 추가 매출 (총액)
          const Text('메뉴 외 매출 / 총액 입력 (원)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _extraCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
                hintText: '예: 320000 (배달앱 정산 총액 등)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 26),
            label: const Text('판매 기록 저장'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}
