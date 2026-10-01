import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show MobileAds;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'notification_service.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/more_screen.dart';
import 'widgets/ad_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  await NotificationService.instance.init();
  // AdMob 초기화 (Android 전용 — 웹 미리보기는 플레이스홀더 사용)
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }
  final appState = AppState();
  await appState.init();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const BaljuManiaApp(),
    ),
  );
}

class BaljuManiaApp extends StatelessWidget {
  const BaljuManiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '발주매니아',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// 탭 전환 요청 (홈 히어로 카드 탭 → 발주/재고 탭으로 이동 등)
  /// 0 홈 / 1 발주 / 2 재고 / 3 거래처 / 4 더보기
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(0);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    MainShell.tabRequest.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    MainShell.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final i = MainShell.tabRequest.value;
    if (i >= 0 && i < _screens.length && i != _index) {
      setState(() => _index = i);
    }
  }

  final _screens = const [
    HomeScreen(),
    OrdersScreen(),
    StockScreen(),
    SuppliersScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: 탭 전환 시 각 화면의 스크롤 위치·입력 상태 유지
      body: SafeArea(child: IndexedStack(index: _index, children: _screens)),
      // iOS식 반투명 블러 탭바
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              border: const Border(
                top: BorderSide(color: Color(0x33C6C6C8), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdBanner(),
                BottomNavigationBar(
                  currentIndex: _index,
                  onTap: (i) => setState(() => _index = i),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded, size: 27),
                        label: '홈'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long_rounded, size: 27),
                        label: '발주'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.inventory_2_rounded, size: 27),
                        label: '재고'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.store_rounded, size: 27),
                        label: '거래처'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.more_horiz_rounded, size: 27),
                        label: '더보기'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
