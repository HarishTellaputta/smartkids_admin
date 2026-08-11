import 'package:flutter/material.dart';

import 'features/dashboard/admin_dashboard_screen.dart';

void main() {
  runApp(const SmartKidsAdminApp());
}

class SmartKidsAdminApp extends StatelessWidget {
  const SmartKidsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartKids Patashala Admin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const AdminDashboardScreen(),
    );
  }
}