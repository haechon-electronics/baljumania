import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'order_edit_screen.dart';
import 'order_detail_screen.dart';
import 'smart_scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final recs = app.orderRecommendations;
    final overdue = app.overdueOrders;
    final pending = app.pendingOrders;
    final lowStock = app.lowStockItems;
    final today = DateFormat('M월 d일 EEEE', 'ko').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.storeName,
                          style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Material(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SmartScanScreen()),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_camera_rounded,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 6),
                                Text('촬영',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(today,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
          ),

          // 요약 카드 3개
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  _SummaryCard(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    value: '${overdue.length}',
                    label: '미입고',
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.accent,
                    value: '${pending.length}',
                    label: '입고 대기',
                  ),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    icon: Icons.inventory_rounded,
                    color: AppColors.primaryLight,
                    value: '${lowStock.length}',
                    label: '재고 부족',
                  ),
                ],
              ),
            ),
          ),

          // 미입고 알림
          if (overdue.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                        icon: Icons.notification_important_rounded,
                        color: AppColors.danger,
                        title: '미입고 알림'),
                    const SizedBox(height: 8),
                    ...overdue.map((o) => _OverdueCard(order: o)),
                  ],
                ),
              ),
            ),

          // AI 발주 추천
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.accent,
                      title: 'AI 발주 추천'),
                  const SizedBox(height: 8),
                  if (recs.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryLight, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('지금 발주할 품목이 없습니다.\n재고가 안정적이에요!',
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Colors.grey.shade700)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...recs.take(5).map((r) => _RecommendCard(
                          item: r['item'] as StockItem,
                          reason: r['reason'] as String,
                          urgent: r['urgent'] as bool,
                        )),
                ],
              ),
            ),
          ),

          // 빠른 메뉴
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                      icon: Icons.grid_view_rounded,
                      color: AppColors.primary,
                      title: '빠른 실행'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QuickButton(
                        icon: Icons.add_shopping_cart_rounded,
                        label: '발주하기',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OrderEditScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _QuickButton(
                        icon: Icons.fact_check_rounded,
                        label: '입고 확인',
                        onTap: () {
                          if (pending.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(
                                      orderId: pending.first.id)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('입고 대기 중인 발주가 없습니다',
                                      style: TextStyle(fontSize: 16))),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SummaryCard(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionTitle(
      {required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final PurchaseOrder order;

  const _OverdueCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final missing = order.lines.where((l) => !l.received).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFFFFF3F3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.supplierName} · ${formatDateKr(order.orderDate)} 발주',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${missing.map((l) => l.itemName).join(', ')} 미입고 (예정일 ${formatDateKr(order.expectedDate)} 지남)',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final StockItem item;
  final String reason;
  final bool urgent;

  const _RecommendCard(
      {required this.item, required this.reason, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final supplier = app.supplierById(item.supplierId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: urgent
                    ? const Color(0xFFFFF3E0)
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                urgent
                    ? Icons.priority_high_rounded
                    : Icons.schedule_rounded,
                color: urgent ? AppColors.accent : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(reason,
                      style: TextStyle(
                          fontSize: 15,
                          color: urgent
                              ? AppColors.accent
                              : AppColors.textGrey)),
                  if (supplier != null)
                    Text('거래처: ${supplier.name}',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textGrey)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(76, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderEditScreen(prefillItem: item)),
              ),
              child: const Text('발주'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary, size: 34),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
