import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/secure_storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/declarations_provider.dart';
import 'providers/traders_provider.dart';
import 'services/auth_service.dart';
import 'services/declaration_service.dart';
import 'services/trader_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_dashboard_screen.dart';

class CustomsBrokerApp extends StatelessWidget {
  const CustomsBrokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorageService();
    final apiClient = ApiClient(storage: storage);
    final authService = AuthService(apiClient: apiClient, storage: storage);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<SecureStorageService>.value(value: storage),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: authService, apiClient: apiClient, storage: storage)
            ..restoreSession(),
        ),
        ChangeNotifierProvider<DeclarationsProvider>(
          create: (_) => DeclarationsProvider(service: DeclarationService(apiClient: apiClient)),
        ),
        ChangeNotifierProvider<TradersProvider>(
          create: (_) => TradersProvider(service: TraderService(apiClient: apiClient)),
        ),
      ],
      child: MaterialApp(
        title: 'دليل المخلص الجمركي اليمني',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
          navigationBarTheme: const NavigationBarThemeData(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const _RootScreen(),
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeDashboardScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
