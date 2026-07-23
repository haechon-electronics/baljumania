import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'stock_edit_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _category = '전체'; // 전체, 식자재, 소모품

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    List<StockItem> items = app.stockItems;
    if (_category != '전체') {
      items = items.where((i) => i.category == _category).toList();
    }
    // 부족한 것 먼저
    items.sort((a, b) {
      if (a.isLow != b.isLow) return a.isLow ? -1 : 1;
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('재고 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StockEditScreen()),
        ),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('품목 추가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['전체', '식자재', '소모품'].map((c) {
                final selected = _category == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _category = c),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.black26),
                      ),
                      child: Text(c,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : AppColors.textDark,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('등록된 품목이 없습니다.\n오른쪽 아래 버튼으로 품목을 추가하세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17, color: AppColors.textGrey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        _StockCard(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockItem item;

  const _StockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final supplier = app.supplierById(item.supplierId);

    // 단가 변동
    Widget? priceChange;
    if (item.prevPrice > 0 && item.prevPrice != item.lastPrice) {
      final up = item.lastPrice > item.prevPrice;
      final pct =
          ((item.lastPrice - item.prevPrice) / item.prevPrice * 100).abs();
      priceChange = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 16,
            color: up ? AppColors.danger : Colors.blue,
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: up ? AppColors.danger : Colors.blue),
          ),
        ],
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StockEditScreen(item: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isLow
                      ? const Color(0xFFFFF3E0)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.category == '소모품'
                      ? Icons.cleaning_services_rounded
                      : Icons.restaurant_rounded,
                  color: item.isLow ? AppColors.accent : AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (item.isLow)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('부족',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.location} · ${supplier?.name ?? '거래처 미지정'}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textGrey),
                    ),
                    Row(
                      children: [
                        Text('단가 ${formatWon(item.lastPrice)}',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textGrey)),
                        if (priceChange != null) ...[
                          const SizedBox(width: 6),
                          priceChange,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${formatQty(item.quantity)}${item.unit}',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: item.isLow
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                  ),
                  if (item.minQuantity > 0)
                    Text('기준 ${formatQty(item.minQuantity)}${item.unit}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
