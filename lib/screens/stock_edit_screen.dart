import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class StockEditScreen extends StatefulWidget {
  final StockItem? item;

  const StockEditScreen({super.key, this.item});

  @override
  State<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends State<StockEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _cycleCtrl;
  late String _category;
  late String _unit;
  late String _location;
  String? _supplierId;

  static const _units = ['kg', 'g', '개', '박스', '단', '모', '팩', '병', 'L', '장', '봉'];
  static const _locations = ['냉장', '냉동', '실온', '창고'];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _qtyCtrl = TextEditingController(
        text: item != null ? _numStr(item.quantity) : '');
    _minQtyCtrl = TextEditingController(
        text: item != null && item.minQuantity > 0
            ? _numStr(item.minQuantity)
            : '');
    _priceCtrl = TextEditingController(
        text: item != null && item.lastPrice > 0
            ? item.lastPrice.toInt().toString()
            : '');
    _cycleCtrl = TextEditingController(
        text: item != null && item.orderCycleDays > 0
            ? item.orderCycleDays.toString()
            : '');
    _category = item?.category ?? '식자재';
    _unit = item?.unit ?? 'kg';
    _location = item?.location ?? '실온';
    _supplierId =
        (item?.supplierId.isNotEmpty ?? false) ? item!.supplierId : null;
  }

  String _numStr(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minQtyCtrl.dispose();
    _priceCtrl.dispose();
    _cycleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('품목 이름을 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final app = context.read<AppState>();
    final item = widget.item ?? StockItem(id: '', name: '');
    item.name = _nameCtrl.text.trim();
    item.category = _category;
    item.unit = _unit;
    item.quantity = double.tryParse(_qtyCtrl.text) ?? 0;
    item.minQuantity = double.tryParse(_minQtyCtrl.text) ?? 0;
    final newPrice = double.tryParse(_priceCtrl.text) ?? 0;
    if (widget.item != null &&
        newPrice != widget.item!.lastPrice &&
        widget.item!.lastPrice > 0) {
      item.prevPrice = widget.item!.lastPrice;
    }
    item.lastPrice = newPrice;
    item.supplierId = _supplierId ?? '';
    item.location = _location;
    item.orderCycleDays = int.tryParse(_cycleCtrl.text) ?? 0;

    await app.saveStockItem(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEdit = widget.item != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? '품목 수정' : '품목 추가'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 26),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('품목 삭제',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    content: Text('${widget.item!.name}을(를) 삭제하시겠습니까?',
                        style: const TextStyle(fontSize: 17)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
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
                  await context
                      .read<AppState>()
                      .deleteStockItem(widget.item!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _FieldLabel('품목 이름'),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(hintText: '예: 양파'),
          ),
          const SizedBox(height: 18),

          const _FieldLabel('분류'),
          Row(
            children: ['식자재', '소모품'].map((c) {
              final selected = _category == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
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
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('현재 재고량'),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.]')),
                      ],
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('단위'),
                    DropdownButtonFormField<String>(
                      initialValue: _unit,
                      style: const TextStyle(
                          fontSize: 18, color: AppColors.textDark),
                      items: _units
                          .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u,
                                  style: const TextStyle(fontSize: 18))))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const _FieldLabel('최소 재고 (이하로 떨어지면 알림)'),
          TextField(
            controller: _minQtyCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(hintText: '예: 5'),
          ),
          const SizedBox(height: 18),

          const _FieldLabel('단가 (원)'),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(hintText: '예: 3500'),
          ),
          const SizedBox(height: 18),

          const _FieldLabel('보관 위치'),
          Wrap(
            spacing: 8,
            children: _locations.map((l) {
              final selected = _location == l;
              return ChoiceChip(
                label: Text(l,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            selected ? Colors.white : AppColors.textDark)),
                selected: selected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                onSelected: (_) => setState(() => _location = l),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          const _FieldLabel('주 거래처'),
          DropdownButtonFormField<String>(
            initialValue: _supplierId,
            hint: const Text('거래처 선택 (선택사항)',
                style: TextStyle(fontSize: 17)),
            style:
                const TextStyle(fontSize: 18, color: AppColors.textDark),
            items: [
              const DropdownMenuItem<String>(
                  value: null,
                  child: Text('미지정', style: TextStyle(fontSize: 18))),
              ...app.suppliers.map((s) => DropdownMenuItem(
                  value: s.id,
                  child:
                      Text(s.name, style: const TextStyle(fontSize: 18)))),
            ],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 18),

          const _FieldLabel('발주 주기 (일) - AI 추천에 사용'),
          TextField(
            controller: _cycleCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18),
            decoration:
                const InputDecoration(hintText: '예: 3 (3일마다 발주)'),
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 26),
            label: Text(isEdit ? '수정 완료' : '품목 등록'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    );
  }
}
