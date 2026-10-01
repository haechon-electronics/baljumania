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
  String _category = '전체'; // 전체 + kStockCategories
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    List<StockItem> items = app.stockItems;
    if (_category != '전체') {
      items = items.where((i) => i.category == _category).toList();
    }
    final q = _q.replaceAll(' ', '').toLowerCase();
    if (q.isNotEmpty) {
      items = items
          .where((i) =>
              i.name.replaceAll(' ', '').toLowerCase().contains(q))
          .toList();
    }
    final showSearch = app.stockItems.length > 8;
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
          if (showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: '품목 이름 검색',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _q.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '검색어 지우기',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _q = '');
                          },
                        ),
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              children: ['전체', ...kStockCategories].map((c) {
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
                ? Center(
                    child: Text(
                        q.isNotEmpty
                            ? '"$_q" 검색 결과가 없어요.'
                            : _category != '전체'
                                ? '$_category 분류에 품목이 없어요.'
                                : '등록된 품목이 없습니다.\n오른쪽 아래 버튼으로 품목을 추가하세요!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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

    return Dismissible(
      key: ValueKey('stock_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            Text('삭제',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          context.read<AppState>().deleteStockItem(item.id),
      child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StockEditScreen(item: item)),
        ),
        // 길게 누르면 수량만 빠르게 조정 (수정 화면 안 거치고)
        onLongPress: () => _quickAdjust(context),
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
                  switch (item.category) {
                    '소모품' => Icons.cleaning_services_rounded,
                    '주류·음료' => Icons.local_bar_rounded,
                    '기타' => Icons.inventory_2_rounded,
                    _ => Icons.restaurant_rounded,
                  },
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
      ),
    );
  }

  /// 수량 빠른 조정 시트: − / + / 직접 입력
  void _quickAdjust(BuildContext context) {
    final app = context.read<AppState>();
    double qty = item.quantity;
    final ctrl = TextEditingController(text: formatQty(qty));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void setQty(double v) {
            qty = v < 0 ? 0 : v;
            ctrl.text = formatQty(qty);
            setSheet(() {});
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${item.name} 수량 조정',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('현재 ${formatQty(item.quantity)}${item.unit}',
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AdjBtn(label: '−5', onTap: () => setQty(qty - 5)),
                    const SizedBox(width: 8),
                    _AdjBtn(label: '−1', onTap: () => setQty(qty - 1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [decimalInputFormatter()],
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(suffixText: item.unit),
                        onChanged: (v) {
                          final d = double.tryParse(v);
                          if (d != null) qty = d;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AdjBtn(label: '+1', onTap: () => setQty(qty + 1)),
                    const SizedBox(width: 8),
                    _AdjBtn(label: '+5', onTap: () => setQty(qty + 5)),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final d = double.tryParse(ctrl.text) ?? qty;
                    item.quantity = d < 0 ? 0 : d;
                    await app.saveStockItem(item);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('저장'),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => ctrl.dispose());
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final usage = context.read<AppState>().stockUsage(item);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('품목 삭제',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
            '${item.name}을(를) 삭제하시겠습니까?'
            '${usage.pendingOrders > 0 ? '\n\n• 입고 대기 발주 ${usage.pendingOrders}건에 들어 있어요. 삭제해도 입고 시 같은 이름으로 자동 재등록됩니다.' : ''}'
            '${usage.menus > 0 ? '\n• 레시피 ${usage.menus}개 메뉴에서 쓰고 있어요. 삭제하면 그 메뉴 원가 계산에서 빠집니다.' : ''}',
            style: const TextStyle(fontSize: 17)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소', style: TextStyle(fontSize: 17))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제',
                  style: TextStyle(
                      fontSize: 17, color: AppColors.danger))),
        ],
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      ),
    );
  }
}
