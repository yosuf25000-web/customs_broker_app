import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'declarations/declarations_list_screen.dart';
import 'traders/traders_list_screen.dart';
import 'accounting/accounting_home_screen.dart';
import 'office/office_profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DeclarationsListScreen(),
    TradersListScreen(),
    AccountingHomeScreen(),
  ];

  final _titles = const ['الإقرارات الجمركية', 'التجار والمستوردون', 'المحاسبة'];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'office_profile') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OfficeProfileScreen()));
              } else if (value == 'logout') {
                await auth.logout();
              } else if (value == 'logout_all') {
                await auth.logoutAllDevices();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(auth.currentUser?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'office_profile', child: Text('بيانات المكتب والشعار')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              const PopupMenuItem(value: 'logout_all', child: Text('تسجيل الخروج من كل الأجهزة')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'الإقرارات'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'التجار'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'المحاسبة'),
        ],
      ),
    );
  }
}
