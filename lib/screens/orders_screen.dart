import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'order_edit_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all'; // all, pending, done

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    List<PurchaseOrder> list = app.orders;
    if (_filter == 'pending') {
      list = list.where((o) => o.status != 'done').toList();
    } else if (_filter == 'done') {
      list = list.where((o) => o.status == 'done').toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('발주 관리')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrderEditScreen()),
        ),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('새 발주',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                    label: '전체',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '입고 대기',
                    selected: _filter == 'pending',
                    onTap: () => setState(() => _filter = 'pending')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '입고 완료',
                    selected: _filter == 'done',
                    onTap: () => setState(() => _filter = 'done')),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('발주 내역이 없습니다.\n오른쪽 아래 버튼으로 발주를 등록하세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17, color: AppColors.textGrey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: list.length,
                    itemBuilder: (context, i) =>
                        _OrderCard(order: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.black26),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final PurchaseOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor, statusBg) = switch (order.status) {
      'done' => ('입고 완료', AppColors.primary, AppColors.primarySoft),
      'partial' => ('부분 입고', AppColors.accent, const Color(0xFFFFF3E0)),
      _ => order.isOverdue
          ? ('미입고!', AppColors.danger, const Color(0xFFFFEBEE))
          : ('입고 대기', AppColors.textGrey, const Color(0xFFF0F0F0)),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.supplierName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusText,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.lines
                    .map((l) =>
                        '${l.itemName} ${formatQty(l.qty)}${l.unit}')
                    .join(', '),
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '발주 ${formatDateKr(order.orderDate)} · 입고예정 ${formatDateKr(order.expectedDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textGrey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatWon(order.totalAmount),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
