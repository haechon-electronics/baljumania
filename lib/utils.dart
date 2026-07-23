import 'package:intl/intl.dart';
import 'models.dart';

final _won = NumberFormat('#,###');

String formatWon(num amount) => '₩${_won.format(amount)}';

String formatQty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

String formatDateKr(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return DateFormat('M월 d일 (E)', 'ko').format(d);
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

/// 발주 문자 자동 생성
String buildOrderMessage({
  required String storeName,
  required PurchaseOrder order,
}) {
  final buf = StringBuffer();
  buf.writeln('사장님 안녕하세요, $storeName입니다.');
  buf.writeln('발주 부탁드립니다.');
  buf.writeln('');
  for (final line in order.lines) {
    buf.writeln('- ${line.itemName} ${formatQty(line.qty)}${line.unit}');
  }
  buf.writeln('');
  final expected = DateTime.tryParse(order.expectedDate);
  if (expected != null) {
    buf.writeln('${DateFormat('M월 d일', 'ko').format(expected)}까지 부탁드립니다.');
  }
  if (order.memo.isNotEmpty) {
    buf.writeln(order.memo);
  }
  buf.write('감사합니다!');
  return buf.toString();
}

/// 미입고 문의 문자 생성
String buildInquiryMessage({
  required String storeName,
  required PurchaseOrder order,
}) {
  final buf = StringBuffer();
  final orderDate = DateTime.tryParse(order.orderDate);
  final dateStr = orderDate != null
      ? DateFormat('M월 d일', 'ko').format(orderDate)
      : order.orderDate;
  buf.writeln('사장님 안녕하세요, $storeName입니다.');
  final missing =
      order.lines.where((l) => !l.received).toList();
  buf.writeln('$dateStr에 발주드린 아래 품목이 아직 도착하지 않아서요.');
  buf.writeln('');
  for (final line in missing) {
    buf.writeln('- ${line.itemName} ${formatQty(line.qty)}${line.unit}');
  }
  buf.writeln('');
  buf.write('확인 부탁드립니다. 감사합니다!');
  return buf.toString();
}
