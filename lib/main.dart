import 'package:flutter/material.dart';

import 'features/auth/register_screen.dart';

void main() {
  runApp(const SmartKidsAdminApp());
}

class SmartKidsAdminApp extends StatelessWidget {
  const SmartKidsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MySchool Admin',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home:RegisterScreen(),
      //home: const AdminDashboardScreen(),
    );
  }
}