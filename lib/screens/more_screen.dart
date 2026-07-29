import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme.dart';
import '../notification_service.dart';
import 'analytics_screen.dart';
import 'consult_screen.dart';
import 'menu_screen.dart';
import 'purchase_screen.dart';
import 'sales_screen.dart';
import 'smart_scan_screen.dart';
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
          // 핵심 기능 그룹 (iOS 설정앱 스타일)
          _Group(children: [
            _IosTile(
              icon: Icons.folder_shared_rounded,
              iconBg: AppColors.primary,
              title: '${app.storeName} 서류지갑',
              subtitle: '사업자번호 · 계좌 · 등록증 사진 바로 전송',
              onTap: () => _go(context, const StoreWalletScreen()),
            ),
            _IosTile(
              icon: Icons.photo_camera_rounded,
              iconBg: const Color(0xFF007AFF),
              title: '스마트 촬영 인식',
              subtitle: '찍기만 하면 영수증·매출일보 자동 판별!',
              onTap: () => _go(context, const SmartScanScreen()),
            ),
            _IosTile(
              icon: Icons.support_agent,
              iconBg: AppColors.accent,
              title: 'AI 업무상담',
              subtitle: '세무 · 노무 · 급여 · 우리가게 데이터 즉답',
              onTap: () => _go(context, const ConsultScreen()),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),

          const _GroupLabel('가게 운영'),
          _Group(children: [
            _IosTile(
              icon: Icons.restaurant_menu_rounded,
              iconBg: const Color(0xFFFF6B57),
              title: '메뉴 & 레시피',
              subtitle: '레시피 붙여넣기 등록 · 원가율 계산',
              onTap: () => _go(context, const MenuScreen()),
            ),
            _IosTile(
              icon: Icons.point_of_sale_rounded,
              iconBg: const Color(0xFF5856D6),
              title: '판매 입력',
              subtitle: '홀/배민/쿠팡이츠 채널별 · 재고 자동 차감',
              onTap: () => _go(context, const SalesScreen()),
            ),
            _IosTile(
              icon: Icons.shopping_bag_rounded,
              iconBg: const Color(0xFFAF52DE),
              title: '간편 구매 기록',
              subtitle: '쿠팡 · 다이소 · 마트 구매 기록',
              onTap: () => _go(context, const PurchaseScreen()),
            ),
            _IosTile(
              icon: Icons.bar_chart_rounded,
              iconBg: const Color(0xFF32ADE6),
              title: '매출 분석',
              subtitle: '채널 · 날씨 · 원가율 · 메뉴 순위 · 단가 변동',
              onTap: () => _go(context, const AnalyticsScreen()),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),

          const _GroupLabel('직원 · 세무'),
          _Group(children: [
            _IosTile(
              icon: Icons.people_rounded,
              iconBg: const Color(0xFF34C759),
              title: '직원 & 급여',
              subtitle: '급여 자동 산정 (3.3% · 4대보험 · 주휴수당)',
              onTap: () => _go(context, const StaffScreen()),
            ),
            _IosTile(
              icon: Icons.description_rounded,
              iconBg: const Color(0xFF8E8E93),
              title: '세무자료 내보내기',
              subtitle: '매입장 · 매출장 · 급여대장 엑셀(CSV) 전송',
              onTap: () => _go(context, const TaxExportScreen()),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),

          const _GroupLabel('설정'),
          _Group(children: [
            _IosTile(
              icon: Icons.storefront_rounded,
              iconBg: AppColors.primary,
              title: '가게 이름',
              subtitle: app.storeName,
              onTap: () => _editStoreName(context, app),
            ),
            _IosTile(
              icon: Icons.auto_awesome,
              iconBg: const Color(0xFFFF9500),
              title: 'AI 정밀인식 설정',
              subtitle: app.geminiApiKey.isEmpty
                  ? '꺼짐 (무료 기본인식 사용 중)'
                  : '켜짐 · Gemini 연결됨',
              onTap: () => _aiSettings(context, app),
            ),
            _IosTile(
              icon: Icons.notifications_active_rounded,
              iconBg: const Color(0xFFFF3B30),
              title: '발주 알림 설정',
              subtitle: app.notifyEnabled
                  ? '켜짐 · 매일 ${app.notifyHour}시 (스마트워치 자동 연동)'
                  : '꺼짐',
              onTap: () => _notifySettings(context, app),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),

          const _GroupLabel('준비중'),
          _Group(children: const [
            _ComingSoonTile(
                icon: Icons.shopping_cart_rounded,
                title: 'B2B 비교 발주',
                subtitle: '더 저렴한 거래처 찾기 (추후 오픈)'),
            _ComingSoonTile(
                icon: Icons.badge_rounded,
                title: '인재 채용',
                subtitle: '우리 가게 직원 구하기 (추후 오픈)',
                isLast: true),
          ]),

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

  void _aiSettings(BuildContext context, AppState app) {
    final ctrl = TextEditingController(text: app.geminiApiKey);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AI 정밀인식 설정 (Gemini)',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '키를 넣으면 영수증·일보·사업자등록증 인식률이 크게 올라가요.\n'
              '비용: 사진 1장당 약 1~5원 (무료 쿼터로도 충분)\n\n'
              '키 발급: aistudio.google.com 접속 → 구글 로그인 →\n'
              '"Get API key" 버튼 → 복사해서 아래에 붙여넣기',
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                labelText: 'Gemini API 키',
                hintText: 'AIza 또는 AQ.로 시작하는 키 붙여넣기',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (app.geminiApiKey.isNotEmpty)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger),
                      onPressed: () {
                        app.setGeminiApiKey('');
                        Navigator.pop(ctx);
                      },
                      child: const Text('키 삭제'),
                    ),
                  ),
                if (app.geminiApiKey.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      app.setGeminiApiKey(ctrl.text);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(ctrl.text.trim().isEmpty
                                ? '무료 기본인식 모드로 설정되었어요'
                                : 'AI 정밀인식이 켜졌어요! 🎉')),
                      );
                    },
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _notifySettings(BuildContext context, AppState app) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('발주 알림 설정',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  '미입고·재고부족·발주주기 도래 시 아침에 알려드려요.\n폰 알림이 울리면 갤럭시워치/애플워치에도 자동으로 울립니다. ⌚',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('알림 받기',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  value: app.notifyEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) {
                    app.setNotifySettings(enabled: v);
                    setSheet(() {});
                  },
                ),
                if (app.notifyEnabled) ...[
                  Row(
                    children: [
                      const Text('알림 시각',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: app.notifyHour,
                        style: const TextStyle(
                            fontSize: 17, color: Colors.black87),
                        items: List.generate(17, (i) => i + 5)
                            .map((h) => DropdownMenuItem(
                                value: h, child: Text('$h시')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            app.setNotifySettings(hour: v);
                            setSheet(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications),
                    label: const Text('테스트 알림 보내기'),
                    onPressed: () {
                      NotificationService.instance.showNow(
                        '${app.storeName} 발주 알림 🔔',
                        '테스트 알림입니다! 워치에서도 확인해보세요.',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '테스트 알림 전송! (웹 미리보기에서는 안 울리고, 폰 설치 후 동작합니다)')),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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

/// iOS 설정앱식 그룹 박스 (흰 라운드 박스 안에 항목들)
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 그룹 위 작은 레이블 (iOS 섹션 타이틀)
class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey)),
    );
  }
}

/// iOS 설정앱식 항목: 컬러 아이콘 뱅지 + 제목 + 옥션 구분선
class _IosTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _IosTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          title: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          subtitle: Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textGrey)),
          trailing: const Icon(Icons.chevron_right,
              size: 22, color: Color(0xFFC7C7CC)),
          onTap: onTap,
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 72),
            child: Divider(),
          ),
      ],
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  final bool isLast;

  const _ComingSoonTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF9A9AA0), size: 23),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A9AA0))),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ],
          ),
          subtitle: Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5, color: Color(0xFFB0B0B6))),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('$title 기능은 다음 업데이트에서 만나요!',
                      style: const TextStyle(fontSize: 16))),
            );
          },
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 72),
            child: Divider(),
          ),
      ],
    );
  }
}
