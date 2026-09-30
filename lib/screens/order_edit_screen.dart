import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'order_detail_screen.dart';

/// 발주 등록 화면
class OrderEditScreen extends StatefulWidget {
  final StockItem? prefillItem;
  final List<OrderLine>? prefillLines; // 구매 메모 스캔 등에서 미리 담아온 품목들
  final String? prefillSupplierId;

  const OrderEditScreen(
      {super.key,
      this.prefillItem,
      this.prefillLines,
      this.prefillSupplierId});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  String? _supplierId;
  final List<OrderLine> _lines = [];
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 1));
  final _memoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefillLines != null) {
      _lines.addAll(widget.prefillLines!);
    }
    if (widget.prefillSupplierId != null &&
        widget.prefillSupplierId!.isNotEmpty) {
      _supplierId = widget.prefillSupplierId;
    }
    final item = widget.prefillItem;
    if (item != null) {
      _supplierId = item.supplierId.isNotEmpty ? item.supplierId : null;
      double suggestedQty = item.minQuantity > 0
          ? (item.minQuantity * 2 - item.quantity).clamp(1, 9999)
          : 1;
      _lines.add(OrderLine(
        itemId: item.id,
        itemName: item.name,
        qty: suggestedQty.roundToDouble(),
        unit: item.unit,
        price: item.lastPrice,
      ));
    }
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount => _lines.fold(0, (s, l) => s + l.total);

  Future<void> _addItemDialog() async {
    final app = context.read<AppState>();
    final selected = await showModalBottomSheet<StockItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ItemPickerSheet(
          items: app.stockItems
              .where((s) => !_lines.any((l) => l.itemId == s.id))
              .toList()),
    );
    if (selected != null) {
      setState(() {
        _lines.add(OrderLine(
          itemId: selected.id,
          itemName: selected.name,
          qty: 1,
          unit: selected.unit,
          price: selected.lastPrice,
        ));
        if (_supplierId == null && selected.supplierId.isNotEmpty) {
          _supplierId = selected.supplierId;
        }
      });
    }
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('발주할 품목을 추가해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('거래처를 선택해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final supplier = app.supplierById(_supplierId!);
    final order = PurchaseOrder(
      id: '',
      supplierId: _supplierId!,
      supplierName: supplier?.name ?? '',
      lines: _lines,
      orderDate: todayIso(),
      expectedDate: _expectedDate.toIso8601String().substring(0, 10),
      memo: _memoCtrl.text.trim(),
    );
    await app.saveOrder(order);
    if (!mounted) return;

    // 저장 후 상세 화면으로 이동 (문자 생성/공유 가능)
    final saved = app.orders.first;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) =>
              OrderDetailScreen(orderId: saved.id, justCreated: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('새 발주')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 거래처 선택
          const Text('거래처',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _supplierId,
            hint: const Text('거래처를 선택하세요', style: TextStyle(fontSize: 17)),
            style: const TextStyle(fontSize: 18, color: AppColors.textDark),
            items: app.suppliers
                .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, style: const TextStyle(fontSize: 18))))
                .toList(),
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 20),

          // 품목 리스트
          Row(
            children: [
              const Text('발주 품목',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addItemDialog,
                icon: const Icon(Icons.add_circle_rounded, size: 24),
                label: const Text('품목 추가',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_lines.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: const Center(
                child: Text('품목 추가 버튼을 눌러\n발주할 품목을 선택하세요',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textGrey)),
              ),
            ),
          ..._lines.asMap().entries.map((e) => _LineEditor(
                line: e.value,
                onChanged: () => setState(() {}),
                onDelete: () => setState(() => _lines.removeAt(e.key)),
              )),

          const SizedBox(height: 20),

          // 입고 예정일
          const Text('입고 예정일',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) setState(() => _expectedDate = picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        _expectedDate.toIso8601String().substring(0, 10)),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 메모
          const Text('메모 (선택)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _memoCtrl,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
                hintText: '예: 오전 중 배송 부탁드립니다'),
          ),
          const SizedBox(height: 24),

          // 총액
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('입고 예정 금액',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(formatWon(_totalAmount),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 26),
            label: const Text('발주 등록'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LineEditor extends StatelessWidget {
  final OrderLine line;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _LineEditor(
      {required this.line, required this.onChanged, required this.onDelete});

  /// 수량·단가 직접 입력 다이얼로그
  Future<void> _editQtyPrice(BuildContext context) async {
    final qtyCtrl = TextEditingController(text: formatQty(line.qty));
    final priceCtrl = TextEditingController(
        text: line.price > 0 ? line.price.toInt().toString() : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(line.itemName,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [decimalInputFormatter()],
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                  labelText: '수량 (${line.unit})', hintText: '예: 3'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '단가 (원)', hintText: '예: 12000'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소', style: TextStyle(fontSize: 17))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final qty = double.tryParse(qtyCtrl.text) ?? line.qty;
      final price = double.tryParse(priceCtrl.text) ?? line.price;
      if (qty > 0) line.qty = qty;
      line.price = price;
      onChanged();
    }
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(line.itemName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger, size: 26),
                ),
              ],
            ),
            Row(
              children: [
                // 수량 조절
                _RoundIconBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (line.qty > 1) {
                      line.qty -= 1;
                      onChanged();
                    }
                  },
                ),
                SizedBox(
                  width: 80,
                  // 수량 탭 → 직접 입력
                  child: InkWell(
                    onTap: () => _editQtyPrice(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${formatQty(line.qty)}${line.unit}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                _RoundIconBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    line.qty += 1;
                    onChanged();
                  },
                ),
                const Spacer(),
                // 단가 영역 탭 → 수량/단가 직접 수정
                InkWell(
                  onTap: () => _editQtyPrice(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 3),
                          Text('단가 ${formatWon(line.price)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                      Text(formatWon(line.total),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(icon, color: AppColors.primary, size: 26),
      ),
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  final List<StockItem> items;

  const _ItemPickerSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('품목 선택',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('추가할 수 있는 품목이 없습니다.\n재고 탭에서 품목을 먼저 등록하세요.',
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textGrey)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(item.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '재고 ${formatQty(item.quantity)}${item.unit} · 단가 ${formatWon(item.lastPrice)}',
                          style: const TextStyle(fontSize: 15)),
                      trailing: const Icon(Icons.add_circle_rounded,
                          color: AppColors.primary, size: 28),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
