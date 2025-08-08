import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: const Center(
        child: Text('Attendance Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
