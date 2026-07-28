import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../utils.dart';

/// 매출 분석 대시보드
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String get _ym =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final monthSales =
        app.sales.where((s) => s.date.startsWith(_ym)).toList();
    final totalSales = app.monthlySalesTotal(_ym);
    final totalPurchase = app.monthlyPurchaseTotal(_ym);
    final costRate =
        totalSales > 0 ? (totalPurchase / totalSales * 100) : 0.0;

    // 채널별 매출
    final Map<String, double> channelSales = {};
    for (final s in monthSales) {
      channelSales[s.channel] =
          (channelSales[s.channel] ?? 0) + app.saleAmount(s);
    }

    // 메뉴별 판매량 순위
    final Map<String, double> menuCount = {};
    for (final s in monthSales) {
      for (final e in s.menuSales.entries) {
        menuCount[e.key] = (menuCount[e.key] ?? 0) + e.value;
      }
    }
    final ranked = menuCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 날씨별 평균 매출
    final Map<String, List<double>> weatherSales = {};
    for (final s in monthSales) {
      if (s.weather.isEmpty) continue;
      weatherSales.putIfAbsent(s.weather, () => []);
      weatherSales[s.weather]!.add(app.saleAmount(s));
    }

    // 단가 변동
    final priceChanges = app.stockItems
        .where((i) => i.prevPrice > 0 && i.prevPrice != i.lastPrice)
        .toList()
      ..sort((a, b) => ((b.lastPrice - b.prevPrice) / b.prevPrice)
          .abs()
          .compareTo(((a.lastPrice - a.prevPrice) / a.prevPrice).abs()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('매출 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month - 1)),
          ),
          Center(
            child: Text('${_month.year}년 ${_month.month}월',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 30),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month + 1)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 월간 요약
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigStat(
                          label: '이달 매출',
                          value: formatWon(totalSales),
                          color: AppColors.primary),
                      _BigStat(
                          label: '이달 매입',
                          value: formatWon(totalPurchase),
                          color: AppColors.textDark),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('재료 원가율  ',
                          style: TextStyle(fontSize: 17)),
                      Text(
                        totalSales > 0
                            ? '${costRate.toStringAsFixed(1)}%'
                            : '-',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: costRate > 40
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (costRate > 40 && totalSales > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('⚠️ 원가율이 40%를 넘었습니다. 단가·메뉴가 점검 필요!',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.danger)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 채널별 매출
          if (channelSales.isNotEmpty) ...[
            const Text('채널별 매출',
                style:
                    TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: channelSales.entries.map((e) {
                    final pct = totalSales > 0
                        ? e.value / totalSales
                        : 0.0;
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                  '${formatWon(e.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 메뉴 순위
          const Text('메뉴 판매 순위',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (ranked.isEmpty)
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('판매 기록이 쌓이면 메뉴별 순위가 표시됩니다',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textGrey)),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: ranked.take(8).toList().asMap().entries.map((e) {
                  final menu = app.menuById(e.value.key);
                  if (menu == null) return const SizedBox.shrink();
                  final cost = app.menuCost(menu);
                  final margin = menu.price - cost;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: e.key < 3
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      child: Text('${e.key + 1}',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: e.key < 3
                                  ? Colors.white
                                  : AppColors.textGrey)),
                    ),
                    title: Text(menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    subtitle: cost > 0
                        ? Text('마진 ${formatWon(margin)}/개',
                            style: const TextStyle(fontSize: 14))
                        : null,
                    trailing: Text('${formatQty(e.value.value)}개',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // 날씨별 매출
          if (weatherSales.isNotEmpty) ...[
            const Text('날씨별 평균 매출',
                style:
                    TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: weatherSales.entries.map((e) {
                  final avg =
                      e.value.reduce((a, b) => a + b) / e.value.length;
                  return ListTile(
                    dense: true,
                    leading: Text(
                      switch (e.key) {
                        '맑음' => '☀️',
                        '흐림' => '☁️',
                        '비' => '🌧️',
                        '눈' => '❄️',
                        '폭염' => '🥵',
                        '한파' => '🥶',
                        _ => '🌤️',
                      },
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text('${e.key} (${e.value.length}일)',
                        style: const TextStyle(fontSize: 16)),
                    trailing: Text(formatWon(avg),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 단가 변동
          if (priceChanges.isNotEmpty) ...[
            const Text('단가 변동',
                style:
                    TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: priceChanges.take(8).map((item) {
                  final up = item.lastPrice > item.prevPrice;
                  final pct = ((item.lastPrice - item.prevPrice) /
                          item.prevPrice *
                          100)
                      .abs();
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      up
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: up ? AppColors.danger : Colors.blue,
                      size: 26,
                    ),
                    title: Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${formatWon(item.prevPrice)} → ${formatWon(item.lastPrice)}',
                        style: const TextStyle(fontSize: 14)),
                    trailing: Text(
                        '${up ? '▲' : '▼'} ${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color:
                                up ? AppColors.danger : Colors.blue)),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BigStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 15, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 21, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
