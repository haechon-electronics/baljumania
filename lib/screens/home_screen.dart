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
          // iOS 대형 타이틀 헤더
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(today,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: AppColors.textGrey
                                    .withValues(alpha: 0.9))),
                        const SizedBox(height: 3),
                        Text(
                          app.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              height: 1.1,
                              color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  // 촬영 버튼: 그라데이션 원형 (iOS 카메라 앱 느낌)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SmartScanScreen()),
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00A86B), Color(0xFF00875A)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00875A)
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.photo_camera_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 히어로 카드: 그라데이션 통합 현황 (토스/애플월렛 감성)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0E9F6E),
                      Color(0xFF057A55),
                      Color(0xFF046C4E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF057A55)
                          .withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('오늘의 가게 현황',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                        const Spacer(),
                        Icon(Icons.storefront_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 22),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _HeroStat(
                            value: '${overdue.length}',
                            label: '미입고',
                            warn: overdue.isNotEmpty),
                        _heroDivider(),
                        _HeroStat(
                            value: '${pending.length}',
                            label: '입고 대기'),
                        _heroDivider(),
                        _HeroStat(
                            value: '${lowStock.length}',
                            label: '재고 부족',
                            warn: lowStock.isNotEmpty),
                      ],
                    ),
                  ],
                ),
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
                    const _SectionTitle(title: '미입고 알림'),
                    const SizedBox(height: 10),
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
                  const _SectionTitle(title: 'AI 발주 추천'),
                  const SizedBox(height: 10),
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

          // 빠른 실행: iOS 위젯형 그라데이션 버튼
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: '빠른 실행'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickButton(
                        icon: Icons.add_shopping_cart_rounded,
                        label: '발주하기',
                        gradient: const [
                          Color(0xFF0E9F6E),
                          Color(0xFF046C4E)
                        ],
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
                        gradient: const [
                          Color(0xFF3B82F6),
                          Color(0xFF1D4ED8)
                        ],
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

/// 히어로 카드 안 통계 항목
class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool warn;

  const _HeroStat(
      {required this.value, required this.label, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      height: 1.0,
                      color: Colors.white)),
              if (warn) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD60A),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

Widget _heroDivider() => Container(
      width: 0.8,
      height: 38,
      color: Colors.white.withValues(alpha: 0.20),
    );

/// iOS식 섹션 타이틀 (아이콘 없이 깔끔하게)
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(title,
          style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textDark)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${missing.map((l) => l.itemName).join(', ')} 미입고 (예정일 ${formatDateKr(order.expectedDate)} 지남)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: urgent
                              ? AppColors.accent
                              : AppColors.textGrey)),
                  if (supplier != null)
                    Text('거래처: ${supplier.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

/// iOS 위젯형 빠른실행 버튼: 흰 카드 + 그라데이션 스쿼클 아이콘
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.last.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 27),
                ),
                const SizedBox(height: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
