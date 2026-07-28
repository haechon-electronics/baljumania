import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models2.dart';
import '../payroll.dart';
import '../theme.dart';
import '../utils.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final menus = app.menus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('메뉴 & 레시피')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'paste',
            backgroundColor: AppColors.accent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RecipePasteScreen()),
            ),
            icon: const Icon(Icons.content_paste_rounded, size: 24),
            label: const Text('레시피 붙여넣기',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuEditScreen()),
            ),
            icon: const Icon(Icons.add_rounded, size: 26),
            label: const Text('메뉴 추가',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: menus.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      '등록된 메뉴가 없습니다.\n\n메모장에 적어둔 레시피가 있다면\n"레시피 붙여넣기"로 한번에 등록하세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 160),
              itemCount: menus.length,
              itemBuilder: (context, i) {
                final menu = menus[i];
                final cost = app.menuCost(menu);
                final costRate =
                    menu.price > 0 ? (cost / menu.price * 100) : 0.0;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    title: Text(menu.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.recipe.isEmpty
                              ? '레시피 미등록'
                              : menu.recipe
                                  .map((r) =>
                                      '${r.name} ${formatQty(r.qty)}${r.unit}')
                                  .join(', '),
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (cost > 0 && menu.price > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '원가 ${formatWon(cost)} · 원가율 ${costRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: costRate > 40
                                    ? AppColors.danger
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatWon(menu.price),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MenuEditScreen(menu: menu)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 레시피 복붙 등록 화면
class RecipePasteScreen extends StatefulWidget {
  const RecipePasteScreen({super.key});

  @override
  State<RecipePasteScreen> createState() => _RecipePasteScreenState();
}

class _RecipePasteScreenState extends State<RecipePasteScreen> {
  final _textCtrl = TextEditingController();
  ParsedRecipe? _parsed;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('레시피 내용을 붙여넣어주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    setState(() => _parsed = parseRecipeText(text));
  }

  Future<void> _save() async {
    final p = _parsed;
    if (p == null || p.lines.isEmpty) return;
    final menu = MenuModel(
      id: '',
      name: p.menuName.isNotEmpty ? p.menuName : '새 메뉴',
      recipe: p.lines,
    );
    // 판매가 입력 다이얼로그
    final priceCtrl = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${menu.name} 판매가',
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: priceCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(hintText: '예: 9000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: const Text('나중에', style: TextStyle(fontSize: 17))),
          TextButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(priceCtrl.text) ?? 0),
            child: const Text('저장',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
    menu.price = price ?? 0;
    if (!mounted) return;
    await context.read<AppState>().saveMenu(menu);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${menu.name} 메뉴가 등록되었습니다!',
              style: const TextStyle(fontSize: 16))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('레시피 붙여넣기')),
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
              '메모장이나 카톡에 적어둔 레시피를 그대로 복사해서 붙여넣으세요.\n\n예시:\n김치찌개: 돼지고기 150g, 김치 200g, 두부 반모, 대파 20g',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
                hintText: '여기에 레시피를 붙여넣으세요'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _analyze,
            icon: const Icon(Icons.auto_awesome_rounded, size: 24),
            label: const Text('AI 분석하기'),
          ),
          if (_parsed != null) ...[
            const SizedBox(height: 20),
            Text(
              '분석 결과: ${_parsed!.menuName.isNotEmpty ? _parsed!.menuName : "(메뉴명 없음)"}',
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_parsed!.lines.isEmpty)
              const Text('재료를 인식하지 못했습니다. 형식을 확인해주세요.',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.danger))
            else
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _parsed!.lines
                      .map((r) => ListTile(
                            dense: true,
                            leading: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.primary),
                            title: Text(r.name,
                                style: const TextStyle(fontSize: 17)),
                            trailing: Text(
                                '${formatQty(r.qty)}${r.unit}',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 14),
            if (_parsed!.lines.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 24),
                label: const Text('이대로 메뉴 등록'),
              ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// 메뉴 수동 등록/수정 화면
class MenuEditScreen extends StatefulWidget {
  final MenuModel? menu;

  const MenuEditScreen({super.key, this.menu});

  @override
  State<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends State<MenuEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late List<RecipeLine> _recipe;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.menu?.name ?? '');
    _priceCtrl = TextEditingController(
        text: widget.menu != null && widget.menu!.price > 0
            ? widget.menu!.price.toInt().toString()
            : '');
    _recipe = widget.menu?.recipe
            .map((r) =>
                RecipeLine(name: r.name, qty: r.qty, unit: r.unit))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _addRecipeLine() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String unit = 'g';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('재료 추가',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration:
                    const InputDecoration(labelText: '재료명', hintText: '예: 돼지고기'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                          labelText: '수량', hintText: '150'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: unit,
                    style: const TextStyle(
                        fontSize: 17, color: AppColors.textDark),
                    items: ['g', 'kg', 'ml', 'L', '개', '모', '단', '장', '스푼']
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => unit = v ?? 'g'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소', style: TextStyle(fontSize: 17))),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (name.isNotEmpty && qty > 0) {
                  setState(() => _recipe.add(
                      RecipeLine(name: name, qty: qty, unit: unit)));
                }
                Navigator.pop(ctx);
              },
              child: const Text('추가',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('메뉴 이름을 입력해주세요', style: TextStyle(fontSize: 16))));
      return;
    }
    final app = context.read<AppState>();
    final menu = widget.menu ?? MenuModel(id: '', name: '');
    menu.name = _nameCtrl.text.trim();
    menu.price = double.tryParse(_priceCtrl.text) ?? 0;
    menu.recipe = _recipe;
    await app.saveMenu(menu);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menu != null;
    final app = context.read<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? '메뉴 수정' : '메뉴 추가'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 26),
              onPressed: () async {
                await app.deleteMenu(widget.menu!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
                labelText: '메뉴 이름', hintText: '예: 김치찌개'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
                labelText: '판매가 (원)', hintText: '예: 9000'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('레시피 (1인분 기준)',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addRecipeLine,
                icon: const Icon(Icons.add_circle_rounded, size: 22),
                label: const Text('재료 추가',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_recipe.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: const Center(
                child: Text(
                    '재료를 등록하면 판매량에 따라\n재고가 자동으로 차감됩니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textGrey)),
              ),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: _recipe.asMap().entries.map((e) {
                  return ListTile(
                    dense: true,
                    title: Text(e.value.name,
                        style: const TextStyle(fontSize: 17)),
                    subtitle: Text(
                        '${formatQty(e.value.qty)}${e.value.unit}',
                        style: const TextStyle(fontSize: 15)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.danger, size: 24),
                      onPressed: () =>
                          setState(() => _recipe.removeAt(e.key)),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 26),
            label: Text(isEdit ? '수정 완료' : '메뉴 등록'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
