import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'models2.dart';
import 'notification_service.dart';
import 'scan_service.dart';

/// 앱 전역 상태 + Hive 저장소
class AppState extends ChangeNotifier {
  late Box _supplierBox;
  late Box _stockBox;
  late Box _orderBox;
  late Box _settingsBox;
  late Box _menuBox;
  late Box _saleBox;
  late Box _purchaseBox;
  late Box _employeeBox;
  late Box _workLogBox;

  List<Supplier> suppliers = [];
  List<StockItem> stockItems = [];
  List<PurchaseOrder> orders = [];
  List<MenuModel> menus = [];
  List<SaleRecord> sales = [];
  List<SimplePurchase> purchases = [];
  List<Employee> employees = [];
  List<WorkLog> workLogs = [];
  StoreInfo storeInfo = StoreInfo();
  String storeName = '우리가게';

  // 알림 설정
  bool notifyEnabled = true;
  int notifyHour = 9; // 아침 알림 시각 (기본 9시)

  // AI 정밀인식 (Gemini) 키
  String get geminiApiKey => ScanService.instance.geminiApiKey;

  bool initialized = false;

  Future<void> init() async {
    await Hive.initFlutter();
    _supplierBox = await Hive.openBox('suppliers');
    _stockBox = await Hive.openBox('stock');
    _orderBox = await Hive.openBox('orders');
    _settingsBox = await Hive.openBox('settings');
    _menuBox = await Hive.openBox('menus');
    _saleBox = await Hive.openBox('sales');
    _purchaseBox = await Hive.openBox('purchases');
    _employeeBox = await Hive.openBox('employees');
    _workLogBox = await Hive.openBox('worklogs');

    _loadAll();

    // 최초 실행 시 샘플 데이터
    if (suppliers.isEmpty && stockItems.isEmpty && orders.isEmpty) {
      final seeded = _settingsBox.get('seeded') as bool? ?? false;
      if (!seeded) {
        await _seedSampleData();
        await _settingsBox.put('seeded', true);
      }
    }

    storeName = _settingsBox.get('storeName') as String? ?? '우리가게';
    final infoMap = _settingsBox.get('storeInfo');
    if (infoMap is Map) {
      storeInfo = StoreInfo.fromMap(infoMap);
    }
    if (storeInfo.storeName.isEmpty) storeInfo.storeName = storeName;
    notifyEnabled = _settingsBox.get('notifyEnabled') as bool? ?? true;
    notifyHour = _settingsBox.get('notifyHour') as int? ?? 9;
    ScanService.instance.geminiApiKey =
        _settingsBox.get('geminiApiKey') as String? ?? '';
    initialized = true;
    notifyListeners();

    // 알림 스케줄 갱신 (비동기, 실패해도 앱 동작에 영향 없음)
    rescheduleNotifications();
  }

  // ===== 알림 =====
  Future<void> setNotifySettings({bool? enabled, int? hour}) async {
    if (enabled != null) {
      notifyEnabled = enabled;
      await _settingsBox.put('notifyEnabled', enabled);
    }
    if (hour != null) {
      notifyHour = hour;
      await _settingsBox.put('notifyHour', hour);
    }
    notifyListeners();
    await rescheduleNotifications();
  }

  Future<void> setGeminiApiKey(String key) async {
    ScanService.instance.geminiApiKey = key.trim();
    await _settingsBox.put('geminiApiKey', key.trim());
    notifyListeners();
  }

  /// 발주주기/미입고/재고부족 기반으로 향후 14일치 아침 알림을 다시 예약
  /// (앱을 오래 안 열어도 2주간 알림 유지)
  Future<void> rescheduleNotifications() async {
    final ns = NotificationService.instance;
    await ns.cancelAll();
    if (!notifyEnabled) return;

    final now = DateTime.now();
    int id = 1;

    for (int day = 0; day < 14; day++) {
      final target = DateTime(now.year, now.month, now.day + day,
          notifyHour, 0);
      if (target.isBefore(now)) continue;

      final msgs = <String>[];

      // 1) 미입고 (예정일 지난 발주) — 매일 아침 리마인드
      final overdue = orders.where((o) => o.isOverdue).toList();
      if (overdue.isNotEmpty) {
        final names = overdue.map((o) => o.supplierName).toSet().join(', ');
        msgs.add('미입고 발주 ${overdue.length}건이 있어요 ($names). 확인해 주세요!');
      }

      // 2) 재고 부족
      final low = stockItems.where((i) => i.isLow).toList();
      if (low.isNotEmpty) {
        final names = low.take(3).map((i) => i.name).join(', ');
        msgs.add('재고 부족: $names${low.length > 3 ? ' 외 ${low.length - 3}개' : ''} — 발주가 필요해요!');
      }

      // 3) 발주 주기 도래 (해당 날짜 기준)
      final dueItems = <String>[];
      for (final item in stockItems) {
        if (item.orderCycleDays > 0 && item.lastOrderDate != null) {
          final last = DateTime.tryParse(item.lastOrderDate!);
          if (last != null) {
            final daysSince =
                DateTime(target.year, target.month, target.day)
                    .difference(DateTime(last.year, last.month, last.day))
                    .inDays;
            if (daysSince >= item.orderCycleDays) dueItems.add(item.name);
          }
        }
      }
      if (dueItems.isNotEmpty) {
        msgs.add('오늘 발주할 품목: ${dueItems.take(4).join(', ')}${dueItems.length > 4 ? ' 외 ${dueItems.length - 4}개' : ''}');
      }

      if (msgs.isEmpty) continue;

      await ns.scheduleAt(
        id: id++,
        title: '$storeName 발주 알림 🔔',
        body: msgs.join('\n'),
        when: target,
      );
      if (id > 40) break;
    }
  }

  void _loadAll() {
    suppliers = _supplierBox.values
        .map((e) => Supplier.fromMap(e as Map))
        .toList();
    stockItems =
        _stockBox.values.map((e) => StockItem.fromMap(e as Map)).toList();
    orders = _orderBox.values
        .map((e) => PurchaseOrder.fromMap(e as Map))
        .toList();
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    menus = _menuBox.values.map((e) => MenuModel.fromMap(e as Map)).toList();
    menus.sort((a, b) => a.name.compareTo(b.name));
    sales = _saleBox.values.map((e) => SaleRecord.fromMap(e as Map)).toList();
    sales.sort((a, b) => b.date.compareTo(a.date));
    purchases = _purchaseBox.values
        .map((e) => SimplePurchase.fromMap(e as Map))
        .toList();
    purchases.sort((a, b) => b.date.compareTo(a.date));
    employees =
        _employeeBox.values.map((e) => Employee.fromMap(e as Map)).toList();
    workLogs =
        _workLogBox.values.map((e) => WorkLog.fromMap(e as Map)).toList();
    workLogs.sort((a, b) => b.date.compareTo(a.date));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ===== 설정 =====
  Future<void> setStoreName(String name) async {
    storeName = name;
    await _settingsBox.put('storeName', name);
    notifyListeners();
  }

  // ===== 거래처 =====
  Future<void> saveSupplier(Supplier s) async {
    if (s.id.isEmpty) s.id = _newId();
    await _supplierBox.put(s.id, s.toMap());
    _loadAll();
    notifyListeners();
  }

  Future<void> deleteSupplier(String id) async {
    await _supplierBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  Supplier? supplierById(String id) {
    try {
      return suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== 재고 품목 =====
  Future<void> saveStockItem(StockItem item) async {
    if (item.id.isEmpty) item.id = _newId();
    await _stockBox.put(item.id, item.toMap());
    _loadAll();
    notifyListeners();
    rescheduleNotifications();
  }

  Future<void> deleteStockItem(String id) async {
    await _stockBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  StockItem? stockById(String id) {
    try {
      return stockItems.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<StockItem> get lowStockItems =>
      stockItems.where((s) => s.isLow).toList();

  // ===== 발주 =====
  Future<void> saveOrder(PurchaseOrder order) async {
    if (order.id.isEmpty) order.id = _newId();
    await _orderBox.put(order.id, order.toMap());

    // 품목의 최근 발주일 갱신
    for (final line in order.lines) {
      final item = stockById(line.itemId);
      if (item != null) {
        item.lastOrderDate = order.orderDate;
        await _stockBox.put(item.id, item.toMap());
      }
    }
    _loadAll();
    notifyListeners();
    rescheduleNotifications();
  }

  Future<void> deleteOrder(String id) async {
    await _orderBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  /// 발주 라인 입고 처리 (재고 증가 + 단가 갱신)
  Future<void> receiveOrderLine(PurchaseOrder order, int lineIndex) async {
    final line = order.lines[lineIndex];
    if (line.received) return;
    line.received = true;

    // 재고 증가 + 단가 이력
    final item = stockById(line.itemId);
    if (item != null) {
      item.quantity += line.qty;
      if (line.price > 0 && line.price != item.lastPrice) {
        item.prevPrice = item.lastPrice;
        item.lastPrice = line.price;
      }
      await _stockBox.put(item.id, item.toMap());
    }

    // 발주 상태 갱신
    final allReceived = order.lines.every((l) => l.received);
    final anyReceived = order.lines.any((l) => l.received);
    order.status = allReceived
        ? 'done'
        : anyReceived
            ? 'partial'
            : 'pending';
    await _orderBox.put(order.id, order.toMap());
    _loadAll();
    notifyListeners();
    rescheduleNotifications();
  }

  /// 전체 입고 처리 (일괄 처리 — 라인마다 리로드/알림 재예약하지 않음)
  Future<void> receiveAllLines(PurchaseOrder order) async {
    // 저장소 기준 최신 발주를 다시 읽어 stale 객체 문제 방지
    final raw = _orderBox.get(order.id);
    final fresh =
        raw is Map ? PurchaseOrder.fromMap(raw) : order;

    bool changed = false;
    for (final line in fresh.lines) {
      if (line.received) continue;
      line.received = true;
      changed = true;

      // 재고 증가 + 단가 이력
      final item = stockById(line.itemId);
      if (item != null) {
        item.quantity += line.qty;
        if (line.price > 0 && line.price != item.lastPrice) {
          item.prevPrice = item.lastPrice;
          item.lastPrice = line.price;
        }
        await _stockBox.put(item.id, item.toMap());
      }
    }
    if (!changed) return;

    fresh.status = 'done';
    await _orderBox.put(fresh.id, fresh.toMap());
    _loadAll();
    notifyListeners();
    rescheduleNotifications();
  }

  /// 미입고 발주 (예정일 지남)
  List<PurchaseOrder> get overdueOrders =>
      orders.where((o) => o.isOverdue).toList();

  /// 입고 대기중 발주
  List<PurchaseOrder> get pendingOrders =>
      orders.where((o) => o.status != 'done').toList();

  /// AI 발주 추천: 발주 주기 도래 + 최소재고 이하 품목
  List<Map<String, dynamic>> get orderRecommendations {
    final List<Map<String, dynamic>> recs = [];
    final today = DateTime.now();

    for (final item in stockItems) {
      // 최소 재고 이하
      if (item.isLow) {
        recs.add({
          'item': item,
          'reason': '재고 부족 (${_fmtQty(item.quantity)}${item.unit} 남음, 기준 ${_fmtQty(item.minQuantity)}${item.unit})',
          'urgent': true,
        });
        continue;
      }
      // 발주 주기 도래
      if (item.orderCycleDays > 0 && item.lastOrderDate != null) {
        final last = DateTime.tryParse(item.lastOrderDate!);
        if (last != null) {
          final daysSince = today.difference(last).inDays;
          if (daysSince >= item.orderCycleDays) {
            recs.add({
              'item': item,
              'reason': '발주 주기 도래 (${item.orderCycleDays}일 주기, 마지막 발주 $daysSince일 전)',
              'urgent': false,
            });
          }
        }
      }
    }
    recs.sort((a, b) => (b['urgent'] as bool ? 1 : 0)
        .compareTo(a['urgent'] as bool ? 1 : 0));
    return recs;
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);

  // ===== 데이터 백업/복원 =====
  /// 모든 데이터를 JSON 문자열로 내보내기
  String exportBackupJson() {
    Map<String, dynamic> mapOf(dynamic e) =>
        Map<String, dynamic>.from(e as Map);
    final data = {
      'app': 'baljumania',
      'backupVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'storeName': storeName,
      'storeInfo': storeInfo.toMap(),
      'notifyEnabled': notifyEnabled,
      'notifyHour': notifyHour,
      'suppliers': _supplierBox.values.map(mapOf).toList(),
      'stock': _stockBox.values.map(mapOf).toList(),
      'orders': _orderBox.values.map(mapOf).toList(),
      'menus': _menuBox.values.map(mapOf).toList(),
      'sales': _saleBox.values.map(mapOf).toList(),
      'purchases': _purchaseBox.values.map(mapOf).toList(),
      'employees': _employeeBox.values.map(mapOf).toList(),
      'worklogs': _workLogBox.values.map(mapOf).toList(),
    };
    return jsonEncode(data);
  }

  /// JSON 문자열에서 데이터 복원. 성공 시 null, 실패 시 에러 메시지 반환.
  Future<String?> importBackupJson(String raw) async {
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic>) {
        return '백업 파일 형식이 올바르지 않아요.';
      }
      data = decoded;
    } catch (_) {
      return '백업 내용을 읽을 수 없어요. 파일 전체를 정확히 붙여넣었는지 확인해주세요.';
    }
    if (data['app'] != 'baljumania') {
      return '발주매니아 백업 파일이 아니에요.';
    }

    Future<void> restoreBox(Box box, String key) async {
      final list = data[key];
      if (list is! List) return;
      await box.clear();
      for (final item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id'] as String? ?? _newId();
          await box.put(id, map);
        }
      }
    }

    try {
      await restoreBox(_supplierBox, 'suppliers');
      await restoreBox(_stockBox, 'stock');
      await restoreBox(_orderBox, 'orders');
      await restoreBox(_menuBox, 'menus');
      await restoreBox(_saleBox, 'sales');
      await restoreBox(_purchaseBox, 'purchases');
      await restoreBox(_employeeBox, 'employees');
      await restoreBox(_workLogBox, 'worklogs');

      // 설정 복원 (geminiApiKey는 기기별 설정이라 제외)
      final name = data['storeName'] as String?;
      if (name != null && name.isNotEmpty) {
        await _settingsBox.put('storeName', name);
        storeName = name;
      }
      final infoMap = data['storeInfo'];
      if (infoMap is Map) {
        await _settingsBox.put(
            'storeInfo', Map<String, dynamic>.from(infoMap));
        storeInfo = StoreInfo.fromMap(infoMap);
      }
      final nEnabled = data['notifyEnabled'];
      if (nEnabled is bool) {
        await _settingsBox.put('notifyEnabled', nEnabled);
        notifyEnabled = nEnabled;
      }
      final nHour = data['notifyHour'];
      if (nHour is int && nHour >= 0 && nHour <= 23) {
        await _settingsBox.put('notifyHour', nHour);
        notifyHour = nHour;
      }
      // 복원했으니 샘플 데이터 재삽입 방지
      await _settingsBox.put('seeded', true);

      _loadAll();
      notifyListeners();
      await rescheduleNotifications();
      return null;
    } catch (e) {
      return '복원 중 오류가 발생했어요: $e';
    }
  }

  // ===== 가게 서류지갑 =====
  Future<void> saveStoreInfo(StoreInfo info) async {
    storeInfo = info;
    await _settingsBox.put('storeInfo', info.toMap());
    if (info.storeName.isNotEmpty && info.storeName != storeName) {
      await setStoreName(info.storeName);
    }
    notifyListeners();
  }

  // ===== 메뉴/레시피 =====
  Future<void> saveMenu(MenuModel menu) async {
    if (menu.id.isEmpty) menu.id = _newId();
    await _menuBox.put(menu.id, menu.toMap());
    _loadAll();
    notifyListeners();
  }

  Future<void> deleteMenu(String id) async {
    await _menuBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  MenuModel? menuById(String id) {
    try {
      return menus.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 메뉴 원가 계산 (레시피 재료명 ↔ 재고 품목명 매칭)
  double menuCost(MenuModel menu) {
    double cost = 0;
    for (final r in menu.recipe) {
      final item = _findStockByName(r.name);
      if (item != null && item.lastPrice > 0) {
        // 단위가 다르면 근사 환산 (kg<->g)
        double qty = r.qty;
        if (r.unit == 'g' && item.unit == 'kg') qty = r.qty / 1000;
        if (r.unit == 'kg' && item.unit == 'g') qty = r.qty * 1000;
        cost += qty * item.lastPrice;
      }
    }
    return cost;
  }

  StockItem? _findStockByName(String name) {
    final n = name.trim();
    try {
      return stockItems.firstWhere((s) => s.name == n);
    } catch (_) {
      try {
        return stockItems
            .firstWhere((s) => s.name.contains(n) || n.contains(s.name));
      } catch (_) {
        return null;
      }
    }
  }

  // ===== 판매 기록 =====
  Future<void> saveSale(SaleRecord sale, {bool deductStock = true}) async {
    if (sale.id.isEmpty) sale.id = _newId();
    await _saleBox.put(sale.id, sale.toMap());

    // 레시피 기반 재고 자동 차감
    if (deductStock) {
      await _applySaleStock(sale, sign: -1);
    }
    _loadAll();
    notifyListeners();
  }

  /// 판매 기록 수정: 기존 재고 차감분 복원 → 새 기록으로 재차감
  Future<void> updateSale(SaleRecord oldSale, SaleRecord newSale) async {
    await _applySaleStock(oldSale, sign: 1); // 이전 차감 복원
    newSale.id = oldSale.id;
    await _saleBox.put(newSale.id, newSale.toMap());
    await _applySaleStock(newSale, sign: -1); // 새 수량 차감
    _loadAll();
    notifyListeners();
  }

  /// 판매 기록의 레시피 기반 재고 반영 (sign: -1 차감, +1 복원)
  Future<void> _applySaleStock(SaleRecord sale, {required int sign}) async {
    for (final entry in sale.menuSales.entries) {
      final menu = menuById(entry.key);
      if (menu == null) continue;
      for (final r in menu.recipe) {
        final item = _findStockByName(r.name);
        if (item != null) {
          double qty = r.qty;
          if (r.unit == 'g' && item.unit == 'kg') qty = r.qty / 1000;
          if (r.unit == 'kg' && item.unit == 'g') qty = r.qty * 1000;
          item.quantity =
              (item.quantity + sign * qty * entry.value).clamp(0, 999999);
          await _stockBox.put(item.id, item.toMap());
        }
      }
    }
  }

  Future<void> deleteSale(String id) async {
    await _saleBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  double saleAmount(SaleRecord sale) {
    double total = sale.extraAmount;
    for (final e in sale.menuSales.entries) {
      final menu = menuById(e.key);
      if (menu != null) total += menu.price * e.value;
    }
    return total;
  }

  // ===== 간편 구매 =====
  Future<void> savePurchase(SimplePurchase p) async {
    if (p.id.isEmpty) p.id = _newId();
    await _purchaseBox.put(p.id, p.toMap());
    _loadAll();
    notifyListeners();
  }

  Future<void> deletePurchase(String id) async {
    await _purchaseBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  // ===== 직원/급여 =====
  Future<void> saveEmployee(Employee e) async {
    if (e.id.isEmpty) e.id = _newId();
    await _employeeBox.put(e.id, e.toMap());
    _loadAll();
    notifyListeners();
  }

  Future<void> deleteEmployee(String id) async {
    await _employeeBox.delete(id);
    // 해당 직원 근무기록도 삭제
    final logs = workLogs.where((w) => w.employeeId == id).toList();
    for (final l in logs) {
      await _workLogBox.delete(l.id);
    }
    _loadAll();
    notifyListeners();
  }

  Employee? employeeById(String id) {
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWorkLog(WorkLog log) async {
    if (log.id.isEmpty) log.id = _newId();
    await _workLogBox.put(log.id, log.toMap());
    _loadAll();
    notifyListeners();
  }

  Future<void> deleteWorkLog(String id) async {
    await _workLogBox.delete(id);
    _loadAll();
    notifyListeners();
  }

  /// 월별 매입 총액 (발주 입고분 + 간편구매)
  double monthlyPurchaseTotal(String yearMonth) {
    double total = 0;
    for (final o in orders) {
      if (o.orderDate.startsWith(yearMonth)) {
        for (final l in o.lines) {
          if (l.received) total += l.total;
        }
      }
    }
    for (final p in purchases) {
      if (p.date.startsWith(yearMonth)) total += p.amount;
    }
    return total;
  }

  /// 월별 매출 총액
  double monthlySalesTotal(String yearMonth) {
    double total = 0;
    for (final s in sales) {
      if (s.date.startsWith(yearMonth)) total += saleAmount(s);
    }
    return total;
  }

  // ===== 샘플 데이터 =====
  Future<void> _seedSampleData() async {
    final s1 = Supplier(
        id: _newId(),
        name: '한마음 식자재',
        phone: '010-1234-5678',
        memo: '채소, 육류 전문',
        type: 'regular');
    await _supplierBox.put(s1.id, s1.toMap());
    final s2 = Supplier(
        id: _newId(),
        name: '두레 유통',
        phone: '010-9876-5432',
        memo: '두부, 계란, 유제품',
        type: 'regular');
    await _supplierBox.put(s2.id, s2.toMap());

    final now = DateTime.now();
    String daysAgo(int d) =>
        now.subtract(Duration(days: d)).toIso8601String().substring(0, 10);

    final items = [
      StockItem(
          id: _newId(),
          name: '양파',
          unit: 'kg',
          quantity: 2,
          minQuantity: 5,
          lastPrice: 3500,
          prevPrice: 3200,
          supplierId: s1.id,
          location: '실온',
          orderCycleDays: 3,
          lastOrderDate: daysAgo(4)),
      StockItem(
          id: _newId(),
          name: '대파',
          unit: '단',
          quantity: 8,
          minQuantity: 3,
          lastPrice: 2100,
          prevPrice: 2500,
          supplierId: s1.id,
          location: '냉장',
          orderCycleDays: 3,
          lastOrderDate: daysAgo(1)),
      StockItem(
          id: _newId(),
          name: '돼지고기(앞다리)',
          unit: 'kg',
          quantity: 12,
          minQuantity: 5,
          lastPrice: 13200,
          prevPrice: 12000,
          supplierId: s1.id,
          location: '냉장',
          orderCycleDays: 2,
          lastOrderDate: daysAgo(1)),
      StockItem(
          id: _newId(),
          name: '두부',
          unit: '모',
          quantity: 6,
          minQuantity: 10,
          lastPrice: 1200,
          prevPrice: 1200,
          supplierId: s2.id,
          location: '냉장',
          orderCycleDays: 2,
          lastOrderDate: daysAgo(3)),
      StockItem(
          id: _newId(),
          name: '위생장갑',
          category: '소모품',
          unit: '박스',
          quantity: 3,
          minQuantity: 1,
          lastPrice: 4500,
          prevPrice: 4500,
          supplierId: '',
          location: '창고',
          orderCycleDays: 14,
          lastOrderDate: daysAgo(10)),
    ];
    for (final i in items) {
      await _stockBox.put(i.id, i.toMap());
    }

    // 샘플 발주 (미입고 1건 포함)
    final order1 = PurchaseOrder(
      id: _newId(),
      supplierId: s2.id,
      supplierName: s2.name,
      lines: [
        OrderLine(
            itemId: items[3].id,
            itemName: '두부',
            qty: 10,
            unit: '모',
            price: 1200),
      ],
      orderDate: daysAgo(2),
      expectedDate: daysAgo(1),
      status: 'pending',
    );
    await _orderBox.put(order1.id, order1.toMap());
  }
}
