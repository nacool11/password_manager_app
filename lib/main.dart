import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/main_vault_screen.dart';
import 'state/session_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: Consumer<SessionManager>(
        builder: (context, session, _) {
          final themeMode =
              session.settings.darkMode ? ThemeMode.dark : ThemeMode.light;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Vault App',
            themeMode: themeMode,
            darkTheme: ThemeData.dark(),
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.indigo,
            ),
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();
    if (!session.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!session.isAuthenticated) {
      return const LoginScreen();
    }
    return const MainVaultScreen();
  }
}
