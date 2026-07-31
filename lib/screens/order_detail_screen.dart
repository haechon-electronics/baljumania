import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../utils.dart';

/// 발주 상세: 입고 체크 + 발주 문자 생성/복사/문자/공유
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool justCreated;

  const OrderDetailScreen(
      {super.key, required this.orderId, this.justCreated = false});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _combined = false; // 같은 거래처 대기 발주 통합 문자 여부

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final orderId = widget.orderId;
    final justCreated = widget.justCreated;
    PurchaseOrder? order;
    try {
      order = app.orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      order = null;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('발주 상세')),
        body: const Center(child: Text('발주를 찾을 수 없습니다')),
      );
    }

    // 같은 거래처의 다른 '입고 대기' 발주들 (통합 문자 대상)
    final samePendingOrders = app.orders
        .where((o) =>
            o.supplierId == order!.supplierId &&
            o.status != 'done')
        .toList();
    final canCombine = samePendingOrders.length >= 2;

    final message = (_combined && canCombine)
        ? buildCombinedOrderMessage(
            storeName: app.storeName, orders: samePendingOrders)
        : buildOrderMessage(storeName: app.storeName, order: order);
    final supplier = app.supplierById(order.supplierId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('발주 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 26),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('발주 삭제',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  content: const Text('이 발주를 삭제하시겠습니까?',
                      style: TextStyle(fontSize: 17)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소',
                            style: TextStyle(fontSize: 17))),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('삭제',
                            style: TextStyle(
                                fontSize: 17, color: AppColors.danger))),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AppState>().deleteOrder(orderId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (justCreated)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        '발주 등록 완료!\n아래에서 발주 문자를 바로 보내보세요.',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // 기본 정보
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(order.supplierName,
                            style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold)),
                      ),
                      _StatusBadge(order: order),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      label: '발주일',
                      value: formatDateKr(order.orderDate)),
                  _InfoRow(
                      label: '입고 예정',
                      value: formatDateKr(order.expectedDate)),
                  if (supplier != null && supplier.phone.isNotEmpty)
                    _InfoRow(label: '연락처', value: supplier.phone),
                  if (order.memo.isNotEmpty)
                    _InfoRow(label: '메모', value: order.memo),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text('입고 예정 금액',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(formatWon(order.totalAmount),
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 입고 체크
          Row(
            children: [
              const Text('입고 확인',
                  style:
                      TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (order.status != 'done')
                TextButton.icon(
                  onPressed: () =>
                      context.read<AppState>().receiveAllLines(order!),
                  icon: const Icon(Icons.done_all_rounded, size: 24),
                  label: const Text('전체 입고',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: order.lines.asMap().entries.map((e) {
                final line = e.value;
                return Column(
                  children: [
                    if (e.key > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Icon(
                        line.received
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: line.received
                            ? AppColors.primary
                            : Colors.grey,
                        size: 32,
                      ),
                      title: Text(line.itemName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: line.received
                                ? TextDecoration.lineThrough
                                : null,
                            color: line.received
                                ? Colors.grey
                                : AppColors.textDark,
                          )),
                      subtitle: Text(
                          '${formatQty(line.qty)}${line.unit} · ${formatWon(line.total)}',
                          style: const TextStyle(fontSize: 15)),
                      trailing: line.received
                          ? const Text('입고됨',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(88, 44),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => context
                                  .read<AppState>()
                                  .receiveOrderLine(order!, e.key),
                              child: const Text('입고 확인'),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 발주 문자
          const Text('발주 문자',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // 같은 거래처 대기 발주가 2건 이상이면 통합 문자 옵션 표시
          if (canCombine) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.merge_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '이 거래처에 대기 중인 발주가 ${samePendingOrders.length}건 있어요',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ToggleChip(
                          label: '이 발주만',
                          selected: !_combined,
                          onTap: () =>
                              setState(() => _combined = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ToggleChip(
                          label:
                              '${samePendingOrders.length}건 합쳐 한 통으로',
                          selected: _combined,
                          onTap: () =>
                              setState(() => _combined = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message,
                  style: const TextStyle(fontSize: 17, height: 1.5)),
            ),
          ),
          const SizedBox(height: 12),

          // 문자 액션 버튼 3개
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.copy_rounded,
                  label: '복사',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('발주 문자가 복사되었습니다!',
                                style: TextStyle(fontSize: 16))),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.sms_rounded,
                  label: '문자 보내기',
                  onTap: () async {
                    final phone = supplier?.phone ?? '';
                    final uri = Uri(
                      scheme: 'sms',
                      path: phone,
                      queryParameters: {'body': message},
                    );
                    try {
                      await launchUrl(uri);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  '문자 앱을 열 수 없습니다. 복사 후 붙여넣기 해주세요.',
                                  style: TextStyle(fontSize: 16))),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: '공유(카톡)',
                  onTap: () async {
                    await Share.share(message);
                  },
                ),
              ),
            ],
          ),

          // 미입고 문의 버튼
          if (order.isOverdue) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1.5),
              ),
              icon: const Icon(Icons.help_outline_rounded, size: 24),
              label: const Text('미입고 문의 문자 보내기'),
              onPressed: () async {
                final inquiry = buildInquiryMessage(
                    storeName: app.storeName, order: order!);
                await Clipboard.setData(ClipboardData(text: inquiry));
                if (context.mounted) {
                  await Share.share(inquiry);
                }
              },
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.black26),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PurchaseOrder order;

  const _StatusBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    final (text, color, bg) = switch (order.status) {
      'done' => ('입고 완료', AppColors.primary, AppColors.primarySoft),
      'partial' => ('부분 입고', AppColors.accent, const Color(0xFFFFF3E0)),
      _ => order.isOverdue
          ? ('미입고!', AppColors.danger, const Color(0xFFFFEBEE))
          : ('입고 대기', AppColors.textGrey, const Color(0xFFF0F0F0)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
