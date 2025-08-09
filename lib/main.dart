import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo Employee App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'System', // Use system font for better consistency
        useMaterial3: true, // Enable Material 3 design
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
      ),
      // Start with login screen
      home: LoginScreen(),
      // Remove static routes since we're passing data through navigation
      // The HomeScreen requires employee data, so we can't use static routes
    );
  }
}