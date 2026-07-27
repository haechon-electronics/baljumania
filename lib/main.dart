import 'package:flutter/material.dart';
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

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

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
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          Container(
            height: 0.6,
            color: const Color(0xFFE5E5EA),
          ),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded, size: 28), label: '홈'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_rounded, size: 28),
                  label: '발주'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_rounded, size: 28),
                  label: '재고'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.store_rounded, size: 28), label: '거래처'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded, size: 28),
                  label: '더보기'),
            ],
          ),
        ],
      ),
    );
  }
}
