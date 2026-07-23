import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 가게 이름 설정
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.storefront_rounded,
                  color: AppColors.primary, size: 30),
              title: const Text('가게 이름',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(app.storeName,
                  style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.edit_rounded, size: 24),
              onTap: () => _editStoreName(context, app),
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('준비 중인 기능',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          const _ComingSoonTile(
              icon: Icons.restaurant_menu_rounded,
              title: '메뉴 & 레시피',
              subtitle: '메뉴판 촬영 자동 등록, AI 레시피 초안'),
          const _ComingSoonTile(
              icon: Icons.point_of_sale_rounded,
              title: '판매 입력',
              subtitle: '일보 촬영 · 수동 입력 · 포스 파일 연동'),
          const _ComingSoonTile(
              icon: Icons.receipt_rounded,
              title: '영수증 분석',
              subtitle: '영수증 촬영으로 재고 · 단가 자동 등록'),
          const _ComingSoonTile(
              icon: Icons.bar_chart_rounded,
              title: '매출 분석',
              subtitle: '날씨 요인 · 배달앱 매출 · 원가율 분석'),
          const _ComingSoonTile(
              icon: Icons.people_rounded,
              title: '직원 & 급여',
              subtitle: '근무 스케줄 · 급여 자동 산정 (3.3%, 4대보험)'),
          const _ComingSoonTile(
              icon: Icons.shopping_cart_rounded,
              title: 'B2B 비교 발주',
              subtitle: '더 저렴한 거래처 찾기 (추후 오픈)'),
          const _ComingSoonTile(
              icon: Icons.badge_rounded,
              title: '인재 채용',
              subtitle: '우리 가게 직원 구하기 (추후 오픈)'),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('발주매니아',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('버전 1.0.0 (1차 개발판)',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('사장님의 가게관리 수첩',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _editStoreName(BuildContext context, AppState app) {
    final ctrl = TextEditingController(text: app.storeName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가게 이름 설정',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(hintText: '예: 맛나식당'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(fontSize: 17))),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await app.setStoreName(name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ComingSoonTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: Colors.grey.shade400, size: 30),
        title: Row(
          children: [
            Flexible(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('2차 개발',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
          ],
        ),
        subtitle: Text(subtitle,
            style:
                TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('$title 기능은 다음 업데이트에서 만나요!',
                    style: const TextStyle(fontSize: 16))),
          );
        },
      ),
    );
  }
}
