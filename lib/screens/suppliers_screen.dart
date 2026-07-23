import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final suppliers = app.suppliers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('거래처 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditSheet(context, null),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('거래처 추가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: suppliers.isEmpty
          ? const Center(
              child: Text('등록된 거래처가 없습니다.\n오른쪽 아래 버튼으로 거래처를 추가하세요!',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 17, color: AppColors.textGrey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              itemCount: suppliers.length,
              itemBuilder: (context, i) {
                final s = suppliers[i];
                final typeLabel = switch (s.type) {
                  'online' => '온라인',
                  'offline' => '오프라인 매장',
                  _ => '정식 거래처',
                };
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
                        switch (s.type) {
                          'online' => Icons.language_rounded,
                          'offline' => Icons.shopping_bag_rounded,
                          _ => Icons.local_shipping_rounded,
                        },
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    title: Text(s.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.phone.isNotEmpty)
                          Text(s.phone,
                              style: const TextStyle(fontSize: 15)),
                        Text(
                            '$typeLabel${s.memo.isNotEmpty ? ' · ${s.memo}' : ''}',
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textGrey)),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.chevron_right_rounded, size: 28),
                    onTap: () => _showEditSheet(context, s),
                  ),
                );
              },
            ),
    );
  }

  static void _showEditSheet(BuildContext context, Supplier? supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _SupplierEditSheet(supplier: supplier),
      ),
    );
  }
}

class _SupplierEditSheet extends StatefulWidget {
  final Supplier? supplier;

  const _SupplierEditSheet({this.supplier});

  @override
  State<_SupplierEditSheet> createState() => _SupplierEditSheetState();
}

class _SupplierEditSheetState extends State<_SupplierEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _memoCtrl;
  late String _type;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.supplier?.phone ?? '');
    _memoCtrl = TextEditingController(text: widget.supplier?.memo ?? '');
    _type = widget.supplier?.type ?? 'regular';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('거래처 이름을 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final app = context.read<AppState>();
    final s = widget.supplier ?? Supplier(id: '', name: '');
    s.name = _nameCtrl.text.trim();
    s.phone = _phoneCtrl.text.trim();
    s.memo = _memoCtrl.text.trim();
    s.type = _type;
    await app.saveSupplier(s);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isEdit ? '거래처 수정' : '거래처 추가',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 26),
                    onPressed: () async {
                      await context
                          .read<AppState>()
                          .deleteSupplier(widget.supplier!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '거래처 이름', hintText: '예: 한마음 식자재'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '전화번호', hintText: '예: 010-1234-5678'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _memoCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '메모', hintText: '예: 채소, 육류 전문'),
            ),
            const SizedBox(height: 16),
            const Text('구분',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ('regular', '정식 거래처'),
                ('online', '온라인(쿠팡 등)'),
                ('offline', '오프라인(마트 등)'),
              ].map((t) {
                final selected = _type == t.$1;
                return ChoiceChip(
                  label: Text(t.$2,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : AppColors.textDark)),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => _type = t.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 26),
              label: Text(isEdit ? '수정 완료' : '거래처 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
