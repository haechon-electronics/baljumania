import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app_state.dart';
import '../models2.dart';
import '../payroll.dart';
import '../theme.dart';
import '../utils.dart';

/// 직원 & 급여 화면
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
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
    final employees = app.employees;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('직원 & 급여'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month - 1)),
          ),
          Center(
            child: Text('${_month.month}월',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 30),
            // 미래 월로는 이동 불가 (데이터 없는 화면 방지)
            onPressed: (_month.year < DateTime.now().year ||
                    (_month.year == DateTime.now().year &&
                        _month.month < DateTime.now().month))
                ? () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1))
                : null,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'msg',
            backgroundColor: AppColors.accent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WorkMessageScreen()),
            ),
            icon: const Icon(Icons.chat_rounded, size: 22),
            label: const Text('직원 메시지 인식',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'addEmp',
            onPressed: () => _showEmployeeSheet(context, null),
            icon: const Icon(Icons.person_add_rounded, size: 24),
            label: const Text('직원 추가',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: employees.isEmpty
          ? const Center(
              child: Text(
                  '등록된 직원이 없습니다.\n직원을 추가하고 근무시간을 기록하면\n급여가 자동으로 계산됩니다.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 17, color: AppColors.textGrey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 160),
              itemCount: employees.length,
              itemBuilder: (context, i) {
                final emp = employees[i];
                final logs = app.workLogs
                    .where((w) =>
                        w.employeeId == emp.id && w.date.startsWith(_ym))
                    .toList();
                final payroll =
                    calculatePayroll(employee: emp, logs: logs);
                return _EmployeeCard(
                    employee: emp,
                    payroll: payroll,
                    month: _month,
                    onEdit: () => _showEmployeeSheet(context, emp));
              },
            ),
    );
  }

  void _showEmployeeSheet(BuildContext context, Employee? emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EmployeeEditSheet(employee: emp),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final PayrollResult payroll;
  final DateTime month;
  final VoidCallback onEdit;

  const _EmployeeCard(
      {required this.employee,
      required this.payroll,
      required this.month,
      required this.onEdit});

  String get _typeLabel => switch (employee.empType) {
        'freelance' => '3.3% 프리랜서',
        'insured' => '4대보험 정직원',
        _ => '단기 알바',
      };

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                      employee.name.isNotEmpty ? employee.name[0] : '?',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                          '$_typeLabel · ${employee.empType == 'insured' ? '월급 ${formatWon(employee.monthlyWage)}' : '시급 ${formatWon(employee.hourlyWage)}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 24)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                    label: '${month.month}월 근무',
                    value:
                        '${payroll.totalHours.toStringAsFixed(payroll.totalHours == payroll.totalHours.roundToDouble() ? 0 : 1)}시간'),
                _MiniStat(
                    label: '세전 급여', value: formatWon(payroll.grossPay)),
                _MiniStat(
                    label: '실지급액',
                    value: formatWon(payroll.netPay),
                    highlight: true),
              ],
            ),
            if (payroll.weeklyHolidayPay > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '💡 주휴수당 ${formatWon(payroll.weeklyHolidayPay)} 포함 (주 15시간 이상 근무)',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.accent)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () => _showWorkLogSheet(context),
                    icon: const Icon(Icons.schedule_rounded, size: 20),
                    label: const Text('근무 기록'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () => _sharePayslip(context, app),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: const Text('명세서 전송'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _WorkLogSheet(employee: employee, month: month),
      ),
    );
  }

  void _sharePayslip(BuildContext context, AppState app) {
    final buf = StringBuffer();
    buf.writeln('[${app.storeName}] ${month.year}년 ${month.month}월 급여명세서');
    buf.writeln('');
    buf.writeln('성명: ${employee.name} ($_typeLabel)');
    buf.writeln(
        '근무시간: ${payroll.totalHours.toStringAsFixed(1)}시간');
    buf.writeln('세전 급여: ${formatWon(payroll.grossPay)}');
    if (payroll.weeklyHolidayPay > 0) {
      buf.writeln('(주휴수당 ${formatWon(payroll.weeklyHolidayPay)} 포함)');
    }
    if (payroll.deductions.isNotEmpty) {
      buf.writeln('');
      buf.writeln('[공제 내역]');
      for (final e in payroll.deductions.entries) {
        buf.writeln('${e.key}: -${formatWon(e.value)}');
      }
    }
    buf.writeln('');
    buf.writeln('실지급액: ${formatWon(payroll.netPay)}');
    buf.writeln('');
    buf.writeln('※ ${payroll.note}');
    Share.share(buf.toString());
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: highlight ? 18 : 16,
                fontWeight: FontWeight.bold,
                color:
                    highlight ? AppColors.primary : AppColors.textDark)),
      ],
    );
  }
}

/// 직원 등록/수정 시트
class _EmployeeEditSheet extends StatefulWidget {
  final Employee? employee;

  const _EmployeeEditSheet({this.employee});

  @override
  State<_EmployeeEditSheet> createState() => _EmployeeEditSheetState();
}

class _EmployeeEditSheetState extends State<_EmployeeEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _wageCtrl;
  late String _empType;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.employee?.name ?? '');
    _empType = widget.employee?.empType ?? 'freelance';
    _wageCtrl = TextEditingController(
        text: widget.employee != null
            ? (_empType == 'insured'
                    ? widget.employee!.monthlyWage
                    : widget.employee!.hourlyWage)
                .toInt()
                .toString()
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('직원 이름을 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final wage = double.tryParse(_wageCtrl.text) ?? 0;
    // 최저시급 체크
    if (_empType != 'insured' && wage > 0 && wage < 10320) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ 최저시급 미달',
              style:
                  TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          content: const Text(
              '입력한 시급이 2026년 최저시급(10,320원)보다 낮습니다.\n그래도 저장하시겠습니까?',
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('다시 입력', style: TextStyle(fontSize: 16))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('저장', style: TextStyle(fontSize: 16))),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    final app = context.read<AppState>();
    final emp = widget.employee ?? Employee(id: '', name: '');
    emp.name = _nameCtrl.text.trim();
    emp.empType = _empType;
    if (_empType == 'insured') {
      emp.monthlyWage = wage;
    } else {
      emp.hourlyWage = wage > 0 ? wage : 10320;
    }
    await app.saveEmployee(emp);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(isEdit ? '직원 정보 수정' : '직원 추가',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 26),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('직원 삭제',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          content: Text(
                              '${widget.employee!.name} 직원을 삭제하시겠습니까?\n근무 기록은 급여 계산에서 제외됩니다.',
                              style: const TextStyle(fontSize: 16)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('취소',
                                    style: TextStyle(fontSize: 17))),
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('삭제',
                                    style: TextStyle(
                                        fontSize: 17,
                                        color: AppColors.danger))),
                          ],
                        ),
                      );
                      if (ok != true || !context.mounted) return;
                      await context
                          .read<AppState>()
                          .deleteEmployee(widget.employee!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                  labelText: '이름', hintText: '예: 김철수'),
            ),
            const SizedBox(height: 14),
            const Text('고용 형태',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ('freelance', '3.3% 프리랜서'),
                ('insured', '4대보험 정직원'),
                ('parttime', '단기 알바'),
              ].map((t) {
                final selected = _empType == t.$1;
                return ChoiceChip(
                  label: Text(t.$2,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : AppColors.textDark)),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  onSelected: (_) => setState(() => _empType = t.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _wageCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: _empType == 'insured' ? '월급 (원)' : '시급 (원)',
                hintText:
                    _empType == 'insured' ? '예: 2400000' : '예: 11000',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 26),
              label: Text(isEdit ? '수정 완료' : '직원 등록'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 근무 기록 시트
class _WorkLogSheet extends StatefulWidget {
  final Employee employee;
  final DateTime month;

  const _WorkLogSheet({required this.employee, required this.month});

  @override
  State<_WorkLogSheet> createState() => _WorkLogSheetState();
}

class _WorkLogSheetState extends State<_WorkLogSheet> {
  DateTime _date = DateTime.now();
  double _start = 17;
  double _end = 22;

  String _hourLabel(double h) {
    final isNextDay = h >= 24;
    final hh = isNextDay ? h - 24 : h;
    final hour = hh.floor();
    final min = ((hh - hour) * 60).round();
    final label = '$hour:${min.toString().padLeft(2, '0')}';
    return isNextDay ? '익일 $label' : label;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ym =
        '${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}';
    final logs = app.workLogs
        .where((w) =>
            w.employeeId == widget.employee.id && w.date.startsWith(ym))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.employee.name} 근무 기록',
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2023, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_date.month}/${_date.day}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: _start,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textDark),
                    items: [
                      for (double h = 6; h <= 23.5; h += 0.5)
                        DropdownMenuItem(
                            value: h, child: Text(_hourLabel(h))),
                    ],
                    onChanged: (v) => setState(() => _start = v ?? 17),
                    decoration:
                        const InputDecoration(labelText: '출근'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    initialValue: _end,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textDark),
                    items: [
                      // 야간 마감 지원: 익일 새벽 6시까지 (24~30 = 익일 0~6시)
                      for (double h = 6; h <= 30; h += 0.5)
                        DropdownMenuItem(
                            value: h, child: Text(_hourLabel(h))),
                    ],
                    onChanged: (v) => setState(() => _end = v ?? 22),
                    decoration:
                        const InputDecoration(labelText: '퇴근'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                if (_end <= _start) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('퇴근 시간이 출근보다 빠릅니다',
                              style: TextStyle(fontSize: 16))));
                  return;
                }
                await app.saveWorkLog(WorkLog(
                  id: '',
                  employeeId: widget.employee.id,
                  date: _date.toIso8601String().substring(0, 10),
                  startHour: _start,
                  endHour: _end,
                ));
              },
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text('근무 추가'),
            ),
            const SizedBox(height: 12),
            if (logs.isNotEmpty) ...[
              const Divider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: logs.map((l) {
                    return ListTile(
                      dense: true,
                      title: Text(
                          '${formatDateKr(l.date)}  ${_hourLabel(l.startHour)} ~ ${_hourLabel(l.endHour)}',
                          style: const TextStyle(fontSize: 16)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${l.hours.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 22, color: AppColors.danger),
                            onPressed: () => app.deleteWorkLog(l.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 직원 메시지 붙여넣기 → 근무시간 자동 인식
class WorkMessageScreen extends StatefulWidget {
  const WorkMessageScreen({super.key});

  @override
  State<WorkMessageScreen> createState() => _WorkMessageScreenState();
}

class _WorkMessageScreenState extends State<WorkMessageScreen> {
  final _textCtrl = TextEditingController();
  String? _employeeId;
  List<ParsedWork> _parsed = [];
  bool _analyzed = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _parsed = parseWorkMessage(text);
      _analyzed = true;
    });
  }

  Future<void> _saveAll() async {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('직원을 선택해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final app = context.read<AppState>();
    for (final p in _parsed) {
      await app.saveWorkLog(WorkLog(
        id: '',
        employeeId: _employeeId!,
        date: p.date.toIso8601String().substring(0, 10),
        startHour: p.startHour,
        endHour: p.endHour,
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_parsed.length}건의 근무 기록이 등록되었습니다!',
              style: const TextStyle(fontSize: 16))));
      Navigator.pop(context);
    }
  }

  String _hourLabel(double h) {
    final hour = h.floor();
    final min = ((h - hour) * 60).round();
    return '$hour:${min.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('직원 메시지 인식')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '직원이 카톡/문자로 보낸 근무시간 메시지를 복사해서 붙여넣으세요.\n\n인식 가능한 예시:\n· "월요일 5시부터 10시 했어요"\n· "3/12 11:00-15:00"\n· "어제 6시반부터 마감까지요"',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _employeeId,
            hint: const Text('직원 선택', style: TextStyle(fontSize: 17)),
            style:
                const TextStyle(fontSize: 18, color: AppColors.textDark),
            items: app.employees
                .map((e) => DropdownMenuItem(
                    value: e.id,
                    child:
                        Text(e.name, style: const TextStyle(fontSize: 18))))
                .toList(),
            onChanged: (v) => setState(() => _employeeId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textCtrl,
            maxLines: 5,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
                hintText: '여기에 직원 메시지를 붙여넣으세요'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.auto_awesome_rounded, size: 24),
            label: const Text('자동 분석하기'),
          ),
          if (_analyzed) ...[
            const SizedBox(height: 20),
            Text('분석 결과 (${_parsed.length}건)',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_parsed.isEmpty)
              const Text(
                  '근무시간을 인식하지 못했습니다.\n날짜(요일)와 시간이 포함되어 있는지 확인해주세요.',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.danger))
            else ...[
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _parsed.asMap().entries.map((e) {
                    final p = e.value;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary),
                      title: Text(
                          '${formatDateKr(p.date.toIso8601String().substring(0, 10))}  ${_hourLabel(p.startHour)} ~ ${_hourLabel(p.endHour)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('"${p.raw}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textGrey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.danger, size: 22),
                        onPressed: () =>
                            setState(() => _parsed.removeAt(e.key)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveAll,
                icon: const Icon(Icons.check_rounded, size: 24),
                label: const Text('근무표에 등록'),
              ),
            ],
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
