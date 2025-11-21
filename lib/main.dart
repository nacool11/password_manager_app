import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'state/session_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void updateTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionManager(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vault App',

        // ADD THESE TWO
        themeMode: _themeMode,
        darkTheme: ThemeData.dark(),

        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.indigo,
        ),

        home: LoginScreen(
          onThemeChanged: updateTheme, // Pass callback
        ),
      ),
    );
  }
}
