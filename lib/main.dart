import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProfitTrackApp());
}

class ProfitTrackApp extends StatelessWidget {
  const ProfitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProfitTrack BD',
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
