// lib/main.dart
// App entry point. Sets up the provider and launches the dashboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/game_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const HamburgerTrainApp());
  });
}

class HamburgerTrainApp extends StatelessWidget {
  const HamburgerTrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Hamburger Train',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF9500),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto', // swap for a fun font later!
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}