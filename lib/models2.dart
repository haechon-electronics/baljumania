// ===== 2~4차 확장 모델: 메뉴/레시피, 판매, 간편구매, 직원/급여, 서류지갑 =====

/// 레시피 재료
class RecipeLine {
  String name; // 재료명
  double qty;
  String unit;

  RecipeLine({required this.name, required this.qty, required this.unit});

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'unit': unit};

  factory RecipeLine.fromMap(Map m) => RecipeLine(
        name: m['name'] as String? ?? '',
        qty: (m['qty'] as num?)?.toDouble() ?? 0,
        unit: m['unit'] as String? ?? '',
      );
}

/// 메뉴 (레시피 포함)
class MenuModel {
  String id;
  String name;
  double price; // 판매가
  List<RecipeLine> recipe;

  MenuModel({
    required this.id,
    required this.name,
    this.price = 0,
    List<RecipeLine>? recipe,
  }) : recipe = recipe ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'recipe': recipe.map((r) => r.toMap()).toList(),
      };

  factory MenuModel.fromMap(Map m) => MenuModel(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        recipe: (m['recipe'] as List? ?? [])
            .map((e) => RecipeLine.fromMap(e as Map))
            .toList(),
      );
}

/// 판매 기록 (일 단위, 채널별)
class SaleRecord {
  String id;
  String date; // ISO
  String channel; // 홀, 배민, 쿠팡이츠, 요기요, 기타
  Map<String, double> menuSales; // menuId -> 판매 수량
  double extraAmount; // 메뉴 미지정 매출 (총액 입력)
  String weather; // 맑음/흐림/비/눈/폭염/한파/'' 

  SaleRecord({
    required this.id,
    required this.date,
    this.channel = '홀',
    Map<String, double>? menuSales,
    this.extraAmount = 0,
    this.weather = '',
  }) : menuSales = menuSales ?? {};

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'channel': channel,
        'menuSales': menuSales,
        'extraAmount': extraAmount,
        'weather': weather,
      };

  factory SaleRecord.fromMap(Map m) => SaleRecord(
        id: m['id'] as String? ?? '',
        date: m['date'] as String? ?? '',
        channel: m['channel'] as String? ?? '홀',
        menuSales: (m['menuSales'] as Map? ?? {}).map(
            (k, v) => MapEntry(k as String, (v as num).toDouble())),
        extraAmount: (m['extraAmount'] as num?)?.toDouble() ?? 0,
        weather: m['weather'] as String? ?? '',
      );
}

/// 간편 구매 기록 (쿠팡/다이소/마트 등)
class SimplePurchase {
  String id;
  String date;
  String source; // 구매처명
  String itemsText; // "물티슈 3개, 위생장갑 1박스"
  double amount;
  String category; // 식자재/소모품

  SimplePurchase({
    required this.id,
    required this.date,
    required this.source,
    this.itemsText = '',
    this.amount = 0,
    this.category = '소모품',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'source': source,
        'itemsText': itemsText,
        'amount': amount,
        'category': category,
      };

  factory SimplePurchase.fromMap(Map m) => SimplePurchase(
        id: m['id'] as String? ?? '',
        date: m['date'] as String? ?? '',
        source: m['source'] as String? ?? '',
        itemsText: m['itemsText'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        category: m['category'] as String? ?? '소모품',
      );
}

/// 직원
class Employee {
  String id;
  String name;
  String empType; // freelance(3.3%), insured(4대보험), parttime(알바)
  double hourlyWage; // 시급
  double monthlyWage; // 월급 (insured일 때)
  String phone;

  Employee({
    required this.id,
    required this.name,
    this.empType = 'parttime',
    this.hourlyWage = 10030,
    this.monthlyWage = 0,
    this.phone = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'empType': empType,
        'hourlyWage': hourlyWage,
        'monthlyWage': monthlyWage,
        'phone': phone,
      };

  factory Employee.fromMap(Map m) => Employee(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        empType: m['empType'] as String? ?? 'parttime',
        hourlyWage: (m['hourlyWage'] as num?)?.toDouble() ?? 10030,
        monthlyWage: (m['monthlyWage'] as num?)?.toDouble() ?? 0,
        phone: m['phone'] as String? ?? '',
      );
}

/// 근무 기록
class WorkLog {
  String id;
  String employeeId;
  String date; // ISO
  double startHour; // 17.0 = 17:00, 17.5 = 17:30
  double endHour;

  WorkLog({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.startHour,
    required this.endHour,
  });

  double get hours => (endHour - startHour).clamp(0, 24);

  Map<String, dynamic> toMap() => {
        'id': id,
        'employeeId': employeeId,
        'date': date,
        'startHour': startHour,
        'endHour': endHour,
      };

  factory WorkLog.fromMap(Map m) => WorkLog(
        id: m['id'] as String? ?? '',
        employeeId: m['employeeId'] as String? ?? '',
        date: m['date'] as String? ?? '',
        startHour: (m['startHour'] as num?)?.toDouble() ?? 0,
        endHour: (m['endHour'] as num?)?.toDouble() ?? 0,
      );
}

/// 가게 서류지갑 정보
class StoreInfo {
  String storeName;
  String bizNumber; // 사업자등록번호
  String address;
  String ownerName;
  String phone;
  String bankAccount; // "국민 123-45-678900 홍길동"
  String? bizCertImage; // base64 (사업자등록증)
  String? bankbookImage; // base64 (통장 앞면)

  StoreInfo({
    this.storeName = '',
    this.bizNumber = '',
    this.address = '',
    this.ownerName = '',
    this.phone = '',
    this.bankAccount = '',
    this.bizCertImage,
    this.bankbookImage,
  });

  Map<String, dynamic> toMap() => {
        'storeName': storeName,
        'bizNumber': bizNumber,
        'address': address,
        'ownerName': ownerName,
        'phone': phone,
        'bankAccount': bankAccount,
        'bizCertImage': bizCertImage,
        'bankbookImage': bankbookImage,
      };

  factory StoreInfo.fromMap(Map m) => StoreInfo(
        storeName: m['storeName'] as String? ?? '',
        bizNumber: m['bizNumber'] as String? ?? '',
        address: m['address'] as String? ?? '',
        ownerName: m['ownerName'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        bankAccount: m['bankAccount'] as String? ?? '',
        bizCertImage: m['bizCertImage'] as String?,
        bankbookImage: m['bankbookImage'] as String?,
      );
}
