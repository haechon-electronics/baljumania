// ===== 데이터 모델 (Hive Map 기반 - 어댑터 없이 유연하게) =====

/// 거래처
class Supplier {
  String id;
  String name;
  String phone;
  String memo; // 취급 품목 등
  String type; // 'regular'(정식거래처), 'online'(쿠팡 등), 'offline'(다이소/마트)

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.memo = '',
    this.type = 'regular',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'memo': memo,
        'type': type,
      };

  factory Supplier.fromMap(Map map) => Supplier(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        memo: map['memo'] as String? ?? '',
        type: map['type'] as String? ?? 'regular',
      );
}

/// 재고 분류 목록 (전 화면 공용)
const List<String> kStockCategories = ['식자재', '주류·음료', '소모품', '기타'];

/// 품목 (재고)
class StockItem {
  String id;
  String name;
  String category; // kStockCategories 중 하나
  String unit; // kg, 개, 박스, 단, 모 등
  double quantity; // 현재 재고량
  double minQuantity; // 최소 재고 (알림 기준)
  double lastPrice; // 최근 단가
  double prevPrice; // 직전 단가 (변동 비교용)
  String supplierId; // 주 거래처
  String location; // 냉장/냉동/실온/창고
  int orderCycleDays; // 발주 주기 (0 = 미설정)
  String? lastOrderDate; // ISO date

  StockItem({
    required this.id,
    required this.name,
    this.category = '식자재',
    this.unit = 'kg',
    this.quantity = 0,
    this.minQuantity = 0,
    this.lastPrice = 0,
    this.prevPrice = 0,
    this.supplierId = '',
    this.location = '실온',
    this.orderCycleDays = 0,
    this.lastOrderDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'quantity': quantity,
        'minQuantity': minQuantity,
        'lastPrice': lastPrice,
        'prevPrice': prevPrice,
        'supplierId': supplierId,
        'location': location,
        'orderCycleDays': orderCycleDays,
        'lastOrderDate': lastOrderDate,
      };

  factory StockItem.fromMap(Map map) => StockItem(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '식자재',
        unit: map['unit'] as String? ?? 'kg',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        minQuantity: (map['minQuantity'] as num?)?.toDouble() ?? 0,
        lastPrice: (map['lastPrice'] as num?)?.toDouble() ?? 0,
        prevPrice: (map['prevPrice'] as num?)?.toDouble() ?? 0,
        supplierId: map['supplierId'] as String? ?? '',
        location: map['location'] as String? ?? '실온',
        orderCycleDays: (map['orderCycleDays'] as num?)?.toInt() ?? 0,
        lastOrderDate: map['lastOrderDate'] as String?,
      );

  bool get isLow => minQuantity > 0 && quantity <= minQuantity;
}

/// 발주 항목 (발주서 내 개별 품목)
class OrderLine {
  String itemId;
  String itemName;
  double qty;
  String unit;
  double price; // 단가
  bool received; // 개별 입고 여부

  OrderLine({
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.unit,
    this.price = 0,
    this.received = false,
  });

  double get total => qty * price;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'itemName': itemName,
        'qty': qty,
        'unit': unit,
        'price': price,
        'received': received,
      };

  factory OrderLine.fromMap(Map map) => OrderLine(
        itemId: map['itemId'] as String? ?? '',
        itemName: map['itemName'] as String? ?? '',
        qty: (map['qty'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        received: map['received'] as bool? ?? false,
      );
}

/// 발주서
class PurchaseOrder {
  String id;
  String supplierId;
  String supplierName;
  List<OrderLine> lines;
  String orderDate; // ISO date
  String expectedDate; // 입고 예정일 ISO date
  String status; // 'pending'(입고대기), 'partial'(부분입고), 'done'(입고완료)
  String memo;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.lines,
    required this.orderDate,
    required this.expectedDate,
    this.status = 'pending',
    this.memo = '',
  });

  double get totalAmount =>
      lines.fold(0, (sum, l) => sum + l.total);

  bool get isOverdue {
    if (status == 'done') return false;
    final expected = DateTime.tryParse(expectedDate);
    if (expected == null) return false;
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day)
        .isAfter(DateTime(expected.year, expected.month, expected.day));
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'lines': lines.map((l) => l.toMap()).toList(),
        'orderDate': orderDate,
        'expectedDate': expectedDate,
        'status': status,
        'memo': memo,
      };

  factory PurchaseOrder.fromMap(Map map) => PurchaseOrder(
        id: map['id'] as String? ?? '',
        supplierId: map['supplierId'] as String? ?? '',
        supplierName: map['supplierName'] as String? ?? '',
        lines: (map['lines'] as List? ?? [])
            .map((e) => OrderLine.fromMap(e as Map))
            .toList(),
        orderDate: map['orderDate'] as String? ?? '',
        expectedDate: map['expectedDate'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        memo: map['memo'] as String? ?? '',
      );
}
