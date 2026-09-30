import 'models2.dart';

/// ===== 급여 자동 산정 (2026년 기준 요율) =====

class PayrollResult {
  final double totalHours;
  final double grossPay; // 세전
  final double weeklyHolidayPay; // 주휴수당
  final Map<String, double> deductions; // 공제 항목
  final double netPay; // 실지급액
  final String note;

  PayrollResult({
    required this.totalHours,
    required this.grossPay,
    required this.weeklyHolidayPay,
    required this.deductions,
    required this.netPay,
    this.note = '',
  });

  double get totalDeduction =>
      deductions.values.fold(0, (s, v) => s + v);
}

/// 월 급여 계산
PayrollResult calculatePayroll({
  required Employee employee,
  required List<WorkLog> logs, // 해당 월 근무기록
}) {
  final totalHours = logs.fold<double>(0, (s, l) => s + l.hours);

  // 주휴수당 계산: 주 15시간 이상 근무한 주마다 (일평균시간 × 시급)
  double weeklyHolidayPay = 0;
  if (employee.empType != 'insured') {
    final Map<String, double> weekHours = {};
    final Map<String, int> weekDays = {};
    for (final l in logs) {
      final d = DateTime.tryParse(l.date);
      if (d == null) continue;
      // 주 식별: 연도-주차
      final firstDay = d.subtract(Duration(days: d.weekday - 1));
      final key = firstDay.toIso8601String().substring(0, 10);
      weekHours[key] = (weekHours[key] ?? 0) + l.hours;
      weekDays[key] = (weekDays[key] ?? 0) + 1;
    }
    for (final e in weekHours.entries) {
      if (e.value >= 15) {
        final days = weekDays[e.key] ?? 1;
        final avgDaily = e.value / days;
        weeklyHolidayPay += avgDaily.clamp(0, 8) * employee.hourlyWage;
      }
    }
  }

  double grossPay;
  final Map<String, double> deductions = {};
  String note = '';

  switch (employee.empType) {
    case 'freelance': // 3.3% 프리랜서
      grossPay = totalHours * employee.hourlyWage + weeklyHolidayPay;
      final tax = (grossPay * 0.03).roundToDouble();
      final localTax = (grossPay * 0.003).roundToDouble();
      deductions['소득세 3%'] = tax;
      deductions['지방소득세 0.3%'] = localTax;
      note = '3.3% 원천징수 (사업소득)';
      break;

    case 'insured': // 4대보험 정직원 (월급제)
      grossPay = employee.monthlyWage;
      final pension = (grossPay * 0.0475).roundToDouble(); // 국민연금 4.75% (2026)
      final health = (grossPay * 0.03595).roundToDouble(); // 건강보험 3.595% (2026)
      final longCare = (health * 0.1314).roundToDouble(); // 장기요양 = 건보료의 13.14% (2026)
      final unemployment = (grossPay * 0.009).roundToDouble(); // 고용보험 0.9%
      // 간이세액 근사 (소규모 근로자 기준 근사치)
      final incomeTax = _approxIncomeTax(grossPay);
      final localTax = (incomeTax * 0.1).roundToDouble();
      deductions['국민연금 4.75%'] = pension;
      deductions['건강보험 3.595%'] = health;
      deductions['장기요양'] = longCare;
      deductions['고용보험 0.9%'] = unemployment;
      deductions['소득세(간이)'] = incomeTax;
      deductions['지방소득세'] = localTax;
      note = '4대보험 공제 (표준요율 기준 참고용)';
      break;

    default: // parttime 알바 (공제 없음 단순 지급)
      grossPay = totalHours * employee.hourlyWage + weeklyHolidayPay;
      note = '단기 알바 (공제 없음)';
  }

  final netPay = grossPay - deductions.values.fold(0.0, (s, v) => s + v);

  return PayrollResult(
    totalHours: totalHours,
    grossPay: grossPay,
    weeklyHolidayPay: weeklyHolidayPay,
    deductions: deductions,
    netPay: netPay,
    note: note,
  );
}

/// 간이세액 근사치 (부양가족 1인 기준)
double _approxIncomeTax(double monthly) {
  if (monthly < 1060000) return 0;
  if (monthly < 1500000) return 5000;
  if (monthly < 2000000) return 16000;
  if (monthly < 2500000) return 33000;
  if (monthly < 3000000) return 67000;
  if (monthly < 3500000) return 105000;
  if (monthly < 4000000) return 152000;
  return monthly * 0.05;
}

/// ===== 직원 메시지 → 근무시간 파싱 =====

class ParsedWork {
  final DateTime date;
  final double startHour;
  final double endHour;
  final String raw;

  ParsedWork({
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.raw,
  });
}

/// "월 5시~10시", "3/12 11:00-15:00", "어제 6시반부터 마감까지" 등 파싱
List<ParsedWork> parseWorkMessage(String text, {double closingHour = 22}) {
  final results = <ParsedWork>[];
  final now = DateTime.now();
  final lines = text
      .split(RegExp(r'[\n,]'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  const weekdayMap = {
    '월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6, '일': 7,
  };

  for (final line in lines) {
    DateTime? date;

    // 날짜: 3/12, 3월 12일
    final dateMatch =
        RegExp(r'(\d{1,2})\s*[/월]\s*(\d{1,2})').firstMatch(line);
    if (dateMatch != null) {
      final m = int.parse(dateMatch.group(1)!);
      final d = int.parse(dateMatch.group(2)!);
      date = DateTime(now.year, m, d);
      if (date.isAfter(now.add(const Duration(days: 7)))) {
        date = DateTime(now.year - 1, m, d);
      }
    }

    // 요일: 월요일/월욜/월
    if (date == null) {
      for (final e in weekdayMap.entries) {
        if (RegExp('${e.key}(요일|욜)').hasMatch(line) ||
            RegExp('(^|[\\s])${e.key}([\\s]|\$)').hasMatch(line)) {
          // 이번 주 해당 요일 (미래면 지난주)
          var candidate =
              now.subtract(Duration(days: now.weekday - e.value));
          if (candidate.isAfter(now)) {
            candidate = candidate.subtract(const Duration(days: 7));
          }
          date = candidate;
          break;
        }
      }
    }

    // 어제/그저께/오늘
    if (date == null) {
      if (line.contains('어제')) {
        date = now.subtract(const Duration(days: 1));
      } else if (line.contains('그저께') || line.contains('그제')) {
        date = now.subtract(const Duration(days: 2));
      } else if (line.contains('오늘')) {
        date = now;
      }
    }

    if (date == null) continue;

    // 시간 범위: 5시~10시, 5시부터 10시까지, 11:00-15:00, 6시반
    double? start;
    double? end;

    final timeRange = RegExp(
            r'(\d{1,2})(?::(\d{2})|시(반)?)?\s*(?:~|-|부터)\s*(\d{1,2}|마감)(?::(\d{2})|시(반)?)?')
        .firstMatch(line);
    if (timeRange != null) {
      final h1 = int.parse(timeRange.group(1)!);
      final m1 = timeRange.group(2) != null
          ? int.parse(timeRange.group(2)!) / 60.0
          : (timeRange.group(3) != null ? 0.5 : 0.0);
      start = h1 + m1;
      // 식당 맥락: 1~9시는 오후로 판단 (11,12는 오전 유지)
      if (h1 >= 1 && h1 <= 9) start = start + 12;

      final g4 = timeRange.group(4)!;
      if (g4 == '마감') {
        end = closingHour;
      } else {
        final h2 = int.parse(g4);
        final m2 = timeRange.group(5) != null
            ? int.parse(timeRange.group(5)!) / 60.0
            : (timeRange.group(6) != null ? 0.5 : 0.0);
        end = h2 + m2;
        if (h2 >= 1 && h2 <= 11 && end <= start) end = end + 12;
      }
    } else if (line.contains('마감')) {
      // "6시반부터 마감까지"
      final startMatch = RegExp(r'(\d{1,2})시(반)?').firstMatch(line);
      if (startMatch != null) {
        var h = int.parse(startMatch.group(1)!).toDouble();
        if (startMatch.group(2) != null) h += 0.5;
        if (h >= 1 && h <= 9) h += 12;
        start = h;
        end = closingHour;
      }
    }

    if (start != null && end != null && end > start) {
      results.add(ParsedWork(
        date: date,
        startHour: start,
        endHour: end,
        raw: line,
      ));
    }
  }
  return results;
}

/// ===== 레시피 복붙 텍스트 파싱 =====

class ParsedRecipe {
  final String menuName;
  final List<RecipeLine> lines;

  ParsedRecipe({required this.menuName, required this.lines});
}

/// "김치찌개: 돼지고기 150g, 김치 200g, 두부 반모" 형식 파싱
ParsedRecipe parseRecipeText(String text) {
  String menuName = '';
  final lines = <RecipeLine>[];

  var body = text.trim();
  // 첫 줄 또는 콜론 앞을 메뉴명으로
  final colonIdx = body.indexOf(':');
  final newlineIdx = body.indexOf('\n');
  if (colonIdx > 0 && (newlineIdx < 0 || colonIdx < newlineIdx)) {
    menuName = body.substring(0, colonIdx).trim();
    body = body.substring(colonIdx + 1);
  } else if (newlineIdx > 0) {
    final firstLine = body.substring(0, newlineIdx).trim();
    // 첫 줄에 숫자가 없으면 메뉴명으로 판단
    if (!RegExp(r'\d').hasMatch(firstLine)) {
      menuName = firstLine;
      body = body.substring(newlineIdx + 1);
    }
  }

  final parts = body
      .split(RegExp(r'[\n,、]'))
      .map((p) => p.trim().replaceFirst(RegExp(r'^[-·•*]\s*'), ''))
      .where((p) => p.isNotEmpty);

  const halfWords = {'반모': 0.5, '반개': 0.5, '반': 0.5};
  const approxWords = {
    '한주먹': 80.0, '한 주먹': 80.0, '한줌': 50.0, '한 줌': 50.0,
    '한스푼': 15.0, '한 스푼': 15.0, '한큰술': 15.0, '한 큰술': 15.0,
    '한작은술': 5.0, '한 작은술': 5.0, '한컵': 200.0, '한 컵': 200.0,
  };

  for (final part in parts) {
    // 표준: 재료명 + 숫자 + 단위
    final m = RegExp(r'^(.+?)\s*(\d+(?:\.\d+)?)\s*(kg|g|ml|L|개|모|단|팩|병|장|봉|스푼|큰술|컵|박스)?\s*$')
        .firstMatch(part);
    if (m != null) {
      lines.add(RecipeLine(
        name: m.group(1)!.trim(),
        qty: double.parse(m.group(2)!),
        unit: m.group(3) ?? '개',
      ));
      continue;
    }
    // "두부 반모" 같은 표현
    bool matched = false;
    for (final e in halfWords.entries) {
      if (part.endsWith(e.key)) {
        final name = part.substring(0, part.length - e.key.length).trim();
        if (name.isNotEmpty) {
          lines.add(RecipeLine(name: name, qty: e.value, unit: '모'));
          matched = true;
        }
        break;
      }
    }
    if (matched) continue;
    // "김치 한주먹" 근사 환산
    for (final e in approxWords.entries) {
      if (part.contains(e.key)) {
        final name = part.replaceAll(e.key, '').trim();
        if (name.isNotEmpty) {
          lines.add(RecipeLine(name: name, qty: e.value, unit: 'g'));
          matched = true;
        }
        break;
      }
    }
    if (!matched && part.length >= 2 && !RegExp(r'\d').hasMatch(part)) {
      // 수량 없는 재료 → 기본 1개
      lines.add(RecipeLine(name: part, qty: 1, unit: '개'));
    }
  }

  return ParsedRecipe(menuName: menuName, lines: lines);
}
