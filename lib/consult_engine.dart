import 'app_state.dart';
import 'payroll.dart';
import 'utils.dart';

/// AI 기초상담 엔진 (규칙 기반)
/// 앱에 저장된 실제 데이터(매출/재고/급여/원가율)를 참고해서 답변합니다.
class ConsultEngine {
  final AppState app;
  ConsultEngine(this.app);

  String get _ym {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String answer(String question) {
    final q = question.replaceAll(' ', '').toLowerCase();

    // ── 앱 데이터 기반 답변 ──
    if (_hasAny(q, ['주휴수당'])) return _weeklyHoliday(q);
    if (_hasAny(q, ['4대보험', '사대보험'])) return _insurance();
    if (_hasAny(q, ['3.3', '삼쩜삼', '프리랜서'])) return _freelance();
    if (_hasAny(q, ['최저시급', '최저임금'])) return _minWage();
    if (_hasAny(q, ['급여', '월급', '알바비', '인건비'])) return _payroll();
    if (_hasAny(q, ['원가율', '원가', '마진'])) return _costRate();
    if (_hasAny(q, ['재고', '발주추천', '뭐발주', '뭐시켜'])) return _stock();
    if (_hasAny(q, ['미입고', '안왔', '안들어왔'])) return _overdue();
    if (_hasAny(q, ['매출', '얼마벌', '장사'])) return _sales();
    if (_hasAny(q, ['부가세', '부가가치세'])) return _vat();
    if (_hasAny(q, ['종합소득세', '종소세'])) return _incomeTax();
    if (_hasAny(q, ['세금계산서'])) return _taxInvoice();
    if (_hasAny(q, ['현금영수증'])) return _cashReceipt();
    if (_hasAny(q, ['퇴직금'])) return _severance();
    if (_hasAny(q, ['근로계약서', '계약서'])) return _contract();
    if (_hasAny(q, ['해고', '권고사직'])) return _dismissal();
    if (_hasAny(q, ['연차', '휴가'])) return _annualLeave();
    if (_hasAny(q, ['야간수당', '연장수당', '초과근무'])) return _overtime();
    if (_hasAny(q, ['위생', '식품위생', '위생교육'])) return _hygiene();
    if (_hasAny(q, ['사업자등록', '사업자내는'])) return _bizReg();
    if (_hasAny(q, ['안녕', 'hi', 'hello', '하이'])) {
      return '안녕하세요 사장님! 😊\n세무·노무·가게 운영 관련해서 편하게 물어보세요.\n\n예를 들어 이렇게요:\n• "이번달 인건비 얼마야?"\n• "주휴수당 계산 어떻게 해?"\n• "원가율 괜찮아?"\n• "부가세 신고 언제까지야?"';
    }

    return '음, 그 질문은 제가 확실하게 답변드리기 어려워요. 🙏\n\n이런 주제는 답변 가능합니다:\n• 급여/주휴수당/4대보험/3.3%/퇴직금\n• 부가세/종합소득세/세금계산서\n• 근로계약서/연차/야간수당\n• 우리가게 매출/원가율/재고/미입고 현황\n\n정확한 세무·법률 판단이 필요하면 세무사/노무사 상담을 권해드려요. (전문가 연결 기능 준비 중입니다!)';
  }

  bool _hasAny(String q, List<String> keys) =>
      keys.any((k) => q.contains(k.replaceAll(' ', '').toLowerCase()));

  // ── 개별 답변 ──

  String _weeklyHoliday(String q) {
    return '📌 주휴수당 기준 (2026년)\n\n'
        '• 1주 15시간 이상 일하면 발생합니다\n'
        '• 계산: 1주 평균 하루 근무시간(최대 8시간) × 시급\n'
        '• 예: 주 20시간(하루 4시간) 알바, 시급 10,320원\n'
        '  → 주휴수당 = 4시간 × 10,320원 = 41,280원/주\n\n'
        '💡 발주매니아 [직원 & 급여]에서 근무시간만 넣으면 주휴수당까지 자동 계산됩니다!';
  }

  String _insurance() {
    return '📌 4대보험 근로자 부담분 (2026년 기준)\n\n'
        '• 국민연금: 4.75%\n'
        '• 건강보험: 3.595%\n'
        '• 장기요양: 건강보험료의 13.14%\n'
        '• 고용보험: 0.9%\n'
        '→ 대략 월급의 약 9.7% 정도가 공제됩니다\n\n'
        '사업주도 비슷한 금액을 부담합니다 (산재보험은 사업주 100%).\n\n'
        '💡 [직원 & 급여]에서 "4대보험" 직원으로 등록하면 자동 공제 계산됩니다.';
  }

  String _freelance() {
    return '📌 3.3% 프리랜서 처리\n\n'
        '• 소득세 3% + 지방소득세 0.3% = 3.3% 원천징수\n'
        '• 4대보험 가입 의무 없음 (사업소득 처리)\n'
        '• 지급명세서 제출 필요 (매년 2월)\n\n'
        '⚠️ 주의: 실제로는 직원처럼 일하는데 3.3%로 처리하면 "위장 프리랜서"로 문제될 수 있어요. 출퇴근 시간이 정해져 있고 지휘를 받으면 근로자로 볼 가능성이 높습니다.\n\n'
        '💡 [직원 & 급여]에서 "3.3% 프리랜서"로 등록하면 자동 계산됩니다.';
  }

  String _minWage() {
    return '📌 최저임금 (2026년)\n\n'
        '• 시급: 10,320원\n'
        '• 일 8시간: 82,560원\n'
        '• 주 40시간 + 주휴 포함 월급: 2,156,880원\n\n'
        '⚠️ 최저시급 미만으로 지급하면 3년 이하 징역 또는 2천만원 이하 벌금 대상이에요.\n\n'
        '💡 발주매니아는 직원 시급이 최저시급 미만이면 자동으로 경고해드립니다!';
  }

  String _payroll() {
    if (app.employees.isEmpty) {
      return '아직 등록된 직원이 없어요.\n\n[더보기 → 직원 & 급여]에서 직원을 등록하고 근무시간을 넣으면 이번달 인건비를 바로 계산해드립니다!';
    }
    double total = 0;
    final lines = <String>[];
    for (final e in app.employees) {
      final logs = app.workLogs
          .where((l) => l.employeeId == e.id && l.date.startsWith(_ym))
          .toList();
      final r = calculatePayroll(employee: e, logs: logs);
      total += r.netPay;
      lines.add('• ${e.name}: ${formatWon(r.netPay)} (${r.totalHours.toStringAsFixed(1)}시간)');
    }
    final sales = app.monthlySalesTotal(_ym);
    final rate = sales > 0 ? (total / sales * 100).toStringAsFixed(1) : null;
    return '📌 이번달 인건비 현황\n\n${lines.join('\n')}\n\n'
        '합계(실지급): ${formatWon(total)}'
        '${rate != null ? '\n매출 대비 인건비율: $rate%' : ''}\n\n'
        '${rate != null && double.parse(rate) > 30 ? '⚠️ 요식업 적정 인건비율은 20~30%예요. 조금 높은 편이니 스케줄 점검을 권해요.' : '💡 요식업 적정 인건비율은 20~30% 수준입니다.'}';
  }

  String _costRate() {
    final sales = app.monthlySalesTotal(_ym);
    final purchase = app.monthlyPurchaseTotal(_ym);
    if (sales == 0) {
      return '이번달 매출 데이터가 아직 없어요.\n\n[더보기 → 판매 입력]에서 매출을 기록하면 원가율을 분석해드립니다!\n\n💡 참고: 요식업 적정 재료 원가율은 30~35%입니다.';
    }
    final rate = purchase / sales * 100;
    String advice;
    if (rate > 40) {
      advice = '⚠️ 원가율이 40%를 넘었어요! 단가 오른 재료가 있는지 [매출 분석 → 단가 변동]을 확인하시고, 메뉴 가격 조정을 고려해보세요.';
    } else if (rate > 35) {
      advice = '조금 높은 편이에요. 로스(버리는 재료) 관리와 거래처 단가 비교를 권해드려요.';
    } else {
      advice = '✅ 양호한 수준이에요! 이대로 유지하시면 됩니다.';
    }
    return '📌 이번달 원가율\n\n'
        '• 매출: ${formatWon(sales)}\n'
        '• 재료비(매입): ${formatWon(purchase)}\n'
        '• 원가율: ${rate.toStringAsFixed(1)}%\n\n'
        '$advice\n\n💡 요식업 적정 원가율: 30~35%';
  }

  String _stock() {
    final recs = app.orderRecommendations;
    if (recs.isEmpty) {
      return '✅ 지금 발주가 급한 품목은 없어요!\n\n재고 부족 기준(최소 재고)과 발주 주기를 설정해두면 제가 알아서 챙겨드립니다. [재고] 탭에서 설정하세요.';
    }
    final lines = recs.take(5).map((r) {
      final item = r['item'];
      return '• ${item.name}: ${r['reason']}';
    }).join('\n');
    return '📌 지금 발주가 필요한 품목\n\n$lines\n\n[홈] 화면에서 [발주] 버튼 누르면 바로 발주서 만들 수 있어요!';
  }

  String _overdue() {
    final od = app.overdueOrders;
    if (od.isEmpty) return '✅ 미입고 발주 없습니다! 다 잘 들어왔어요.';
    final lines = od
        .map((o) =>
            '• ${o.supplierName} (예정일 ${formatDateKr(o.expectedDate)}) — ${o.lines.where((l) => !l.received).map((l) => l.itemName).join(', ')}')
        .join('\n');
    return '⚠️ 미입고 발주 ${od.length}건\n\n$lines\n\n[발주] 탭에서 해당 발주 열면 "미입고 문의 문자"를 자동으로 만들어드려요!';
  }

  String _sales() {
    final sales = app.monthlySalesTotal(_ym);
    final purchase = app.monthlyPurchaseTotal(_ym);
    if (sales == 0) {
      return '이번달 매출 기록이 아직 없어요.\n\n[더보기 → 판매 입력]에서 오늘 판매를 기록해보세요. 채널별(홀/배민/쿠팡이츠)로 나눠서 분석해드립니다!';
    }
    return '📌 이번달 현황\n\n'
        '• 매출: ${formatWon(sales)}\n'
        '• 재료비: ${formatWon(purchase)}\n'
        '• 대략 남는 돈(재료비만 뺀): ${formatWon(sales - purchase)}\n\n'
        '자세한 채널별/메뉴별 분석은 [더보기 → 매출 분석]에서 보실 수 있어요!';
  }

  String _vat() {
    return '📌 부가가치세 신고 일정\n\n'
        '• 일반과세자: 1년 2회\n'
        '  - 1기(1~6월분): 7월 25일까지\n'
        '  - 2기(7~12월분): 다음해 1월 25일까지\n'
        '• 간이과세자: 1년 1회 (다음해 1월 25일까지)\n\n'
        '💡 [더보기 → 세무자료 내보내기]에서 매입장/매출장을 뽑아 세무사님께 보내면 편해요!';
  }

  String _incomeTax() {
    return '📌 종합소득세\n\n'
        '• 신고기간: 매년 5월 1일 ~ 5월 31일\n'
        '• 전년도 1~12월 소득에 대해 신고\n'
        '• 성실신고확인 대상자는 6월 30일까지\n\n'
        '💡 매입 증빙(세금계산서, 카드매입)을 잘 모아두면 세금이 확 줄어요. [간편 구매 기록]에 쿠팡/다이소 구매도 꼬박꼬박 남겨두세요!';
  }

  String _taxInvoice() {
    return '📌 세금계산서\n\n'
        '• 사업자 간 거래 시 발행 (부가세 10% 별도)\n'
        '• 전자세금계산서: 홈택스나 발행 앱에서 발행\n'
        '• 매입 세금계산서 = 부가세 공제 + 비용 인정 → 꼭 챙기세요!\n\n'
        '💡 식자재 거래처에 "세금계산서 발행해주세요"라고 요청하면 부가세 신고 때 공제받을 수 있습니다.';
  }

  String _cashReceipt() {
    return '📌 현금영수증\n\n'
        '• 음식점은 현금영수증 의무발행 업종입니다\n'
        '• 건당 10만원 이상 현금 거래 시 소비자가 요청 안 해도 의무 발행\n'
        '• 미발행 시 거래대금의 20% 가산세!\n\n'
        '⚠️ 손님이 안 달라고 해도 10만원 이상이면 자진발행(국세청 지정번호 010-000-1234)으로 처리하세요.';
  }

  String _severance() {
    return '📌 퇴직금\n\n'
        '• 1년 이상 + 주 15시간 이상 근무자에게 발생 (알바도 해당!)\n'
        '• 계산: 평균임금 30일분 × 근속연수\n'
        '• 퇴직 후 14일 이내 지급 의무\n\n'
        '⚠️ "알바라서 퇴직금 없다"는 건 잘못된 상식이에요. 주 15시간 이상 1년 넘게 일한 알바는 퇴직금 지급 대상입니다.';
  }

  String _contract() {
    return '📌 근로계약서\n\n'
        '• 알바 포함 모든 직원과 서면 작성 의무!\n'
        '• 미작성 시 500만원 이하 벌금 (적발 사례 많아요)\n'
        '• 필수 기재: 임금, 근로시간, 휴일, 연차, 업무내용\n\n'
        '💡 고용노동부 표준근로계약서 양식을 쓰시면 안전합니다. 알바 첫 출근 전에 꼭 쓰고 한 부씩 나눠가지세요!';
  }

  String _dismissal() {
    return '📌 해고 관련 (조심하셔야 해요!)\n\n'
        '• 해고는 30일 전 예고 필수 (또는 30일분 통상임금 지급)\n'
        '• 5인 이상 사업장: 정당한 사유 없는 해고는 부당해고\n'
        '• 해고 사유·시기를 서면 통지해야 효력 있음\n\n'
        '⚠️ 문자·카톡 해고 통보는 분쟁 시 불리할 수 있어요. 이 부분은 꼭 노무사 상담을 받아보시길 권합니다.';
  }

  String _annualLeave() {
    return '📌 연차휴가 (5인 이상 사업장)\n\n'
        '• 1년 미만: 1개월 개근 시 1일씩\n'
        '• 1년 이상: 15일 (2년마다 1일씩 추가, 최대 25일)\n'
        '• 미사용 연차는 수당으로 지급\n\n'
        '💡 5인 미만 사업장은 연차 의무가 없지만, 주휴수당·퇴직금·최저임금은 똑같이 적용됩니다!';
  }

  String _overtime() {
    return '📌 연장·야간·휴일수당 (5인 이상 사업장)\n\n'
        '• 연장근로(1일 8시간 초과): 시급의 1.5배\n'
        '• 야간근로(밤 10시~새벽 6시): +0.5배 가산\n'
        '• 휴일근로: 1.5배 (8시간 초과분은 2배)\n\n'
        '💡 5인 미만 사업장은 가산수당 의무가 없어요 (기본 시급만 지급하면 됨). 직원 수에 따라 달라지니 참고하세요!';
  }

  String _hygiene() {
    return '📌 식품위생 필수 체크\n\n'
        '• 위생교육: 영업자 매년 3시간 (온라인 가능, 식품위생교육원)\n'
        '• 건강진단(보건증): 직원 전원, 1년마다 갱신\n'
        '• 유통기한 지난 재료 보관만 해도 적발 대상!\n\n'
        '💡 보건증 만료일을 달력에 적어두세요. 위반 시 과태료 + 영업정지까지 갈 수 있어요.';
  }

  String _bizReg() {
    return '📌 사업자등록\n\n'
        '• 영업 시작일로부터 20일 이내 신청 (홈택스 or 세무서)\n'
        '• 음식점은 영업신고증(구청 위생과) 먼저 필요\n'
        '• 연매출 1억 4백만원 미만 예상 시 간이과세 선택 가능\n\n'
        '💡 사업자등록번호는 [더보기 → 가게 서류지갑]에 저장해두면 거래처에 바로 보낼 수 있어요!';
  }

  /// 추천 질문 (빠른 버튼)
  static const quickQuestions = [
    '이번달 인건비 얼마야?',
    '원가율 괜찮아?',
    '뭐 발주해야 돼?',
    '주휴수당 계산법',
    '부가세 신고 언제야?',
    '알바 근로계약서 꼭 써야해?',
    '알바도 퇴직금 줘야해?',
    '4대보험 얼마나 떼?',
  ];
}
