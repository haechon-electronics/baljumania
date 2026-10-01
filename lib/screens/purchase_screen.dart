import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../models2.dart';
import '../theme.dart';
import '../utils.dart';

/// 간편 구매 기록 (쿠팡/다이소/마트 등)
class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final purchases = app.purchases;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('간편 구매 기록')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditSheet(context),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('구매 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '쿠팡, 다이소, 마트 등에서 산 것들을 기록하세요.\n총 재료원가 계산에 자동으로 합산됩니다.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          Expanded(
            child: purchases.isEmpty
                ? const Center(
                    child: Text('구매 기록이 없습니다',
                        style: TextStyle(
                            fontSize: 17, color: AppColors.textGrey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: purchases.length,
                    itemBuilder: (context, i) {
                      final p = purchases[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: AppColors.primary,
                                size: 24),
                          ),
                          title: Text(
                              '${p.source} · ${formatDateKr(p.date)}',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          subtitle: p.itemsText.isNotEmpty
                              ? Text(p.itemsText,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Text(formatWon(p.amount),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          // 탭 → 수정, 길게 → 삭제
                          onTap: () => _showEditSheet(context, purchase: p),
                          onLongPress: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('기록 삭제',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                content: Text(
                                    '${p.source} 구매 기록(${formatWon(p.amount)})을 삭제하시겠습니까?',
                                    style:
                                        const TextStyle(fontSize: 16)),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('취소',
                                          style: TextStyle(
                                              fontSize: 17))),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('삭제',
                                          style: TextStyle(
                                              fontSize: 17,
                                              color:
                                                  AppColors.danger))),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              await context
                                  .read<AppState>()
                                  .deletePurchase(p.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static void _showEditSheet(BuildContext context, {SimplePurchase? purchase}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _PurchaseEditSheet(purchase: purchase),
      ),
    );
  }
}

class _PurchaseEditSheet extends StatefulWidget {
  final SimplePurchase? purchase; // null이면 신규
  const _PurchaseEditSheet({this.purchase});

  @override
  State<_PurchaseEditSheet> createState() => _PurchaseEditSheetState();
}

class _PurchaseEditSheetState extends State<_PurchaseEditSheet> {
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _itemsCtrl;
  late final TextEditingController _amountCtrl;
  late String _category;
  late DateTime _date;

  bool get _isEdit => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    final p = widget.purchase;
    _sourceCtrl = TextEditingController(text: p?.source ?? '');
    _itemsCtrl = TextEditingController(text: p?.itemsText ?? '');
    _amountCtrl = TextEditingController(
        text: p != null && p.amount > 0 ? p.amount.toInt().toString() : '');
    _category = p?.category ?? '소모품';
    _date = (p != null ? DateTime.tryParse(p.date) : null) ?? DateTime.now();
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _itemsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_sourceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('구매처를 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('구매 금액을 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final p = SimplePurchase(
      id: widget.purchase?.id ?? '',
      date: _date.toIso8601String().substring(0, 10),
      source: _sourceCtrl.text.trim(),
      itemsText: _itemsCtrl.text.trim(),
      amount: amount,
      category: _category,
    );
    await context.read<AppState>().savePurchase(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? '구매 기록 수정' : '구매 기록 추가',
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                        labelText: '구매처', hintText: '예: 쿠팡, 다이소'),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2023, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        '${_date.month}/${_date.day}',
                        style: const TextStyle(fontSize: 17)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemsCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '구매 품목 (쿠팡 주문내역 복붙 가능)',
                  hintText: '예: 물티슈 3개, 위생장갑 1박스'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '총 금액 (원)', hintText: '예: 32000'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: kStockCategories.map((c) {
                final selected = _category == c;
                return ChoiceChip(
                  label: Text(c,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : AppColors.textDark)),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 26),
              label: Text(_isEdit ? '수정 완료' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}
