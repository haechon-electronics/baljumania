import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import 'analytics_screen.dart';
import 'menu_screen.dart';
import 'purchase_screen.dart';
import 'sales_screen.dart';
import 'staff_screen.dart';
import 'store_wallet_screen.dart';
import 'tax_export_screen.dart';

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
          // 가게 서류지갑 (강조 카드)
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.primary,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const Icon(Icons.folder_shared_rounded,
                  color: Colors.white, size: 32),
              title: Text('${app.storeName} 서류지갑',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              subtitle: const Text('사업자번호 · 계좌 · 등록증 사진 바로 전송',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              trailing: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 28),
              onTap: () => _go(context, const StoreWalletScreen()),
            ),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('가게 운영',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _MenuTile(
            icon: Icons.restaurant_menu_rounded,
            title: '메뉴 & 레시피',
            subtitle: '레시피 붙여넣기 등록 · 원가율 계산',
            onTap: () => _go(context, const MenuScreen()),
          ),
          _MenuTile(
            icon: Icons.point_of_sale_rounded,
            title: '판매 입력',
            subtitle: '홀/배민/쿠팡이츠 채널별 · 재고 자동 차감',
            onTap: () => _go(context, const SalesScreen()),
          ),
          _MenuTile(
            icon: Icons.shopping_bag_rounded,
            title: '간편 구매 기록',
            subtitle: '쿠팡 · 다이소 · 마트 구매 기록',
            onTap: () => _go(context, const PurchaseScreen()),
          ),
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            title: '매출 분석',
            subtitle: '채널 · 날씨 · 원가율 · 메뉴 순위 · 단가 변동',
            onTap: () => _go(context, const AnalyticsScreen()),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('직원 · 세무',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _MenuTile(
            icon: Icons.people_rounded,
            title: '직원 & 급여',
            subtitle: '급여 자동 산정 (3.3% · 4대보험 · 주휴수당)',
            onTap: () => _go(context, const StaffScreen()),
          ),
          _MenuTile(
            icon: Icons.description_rounded,
            title: '세무자료 내보내기',
            subtitle: '매입장 · 매출장 · 급여대장 엑셀(CSV) 전송',
            onTap: () => _go(context, const TaxExportScreen()),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('설정 · 준비중',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _MenuTile(
            icon: Icons.storefront_rounded,
            title: '가게 이름',
            subtitle: app.storeName,
            onTap: () => _editStoreName(context, app),
          ),
          const _ComingSoonTile(
              icon: Icons.receipt_rounded,
              title: '영수증 · 일보 사진 인식',
              subtitle: '사진 촬영으로 자동 등록 (다음 업데이트)'),
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
                Text('버전 1.0.0',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('사장님의 AI 가게관리 수첩',
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

  static void _go(BuildContext context, Widget screen) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: AppColors.primary, size: 30),
        title: Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style:
                TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right, size: 26),
        onTap: onTap,
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
              child: const Text('준비중',
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
