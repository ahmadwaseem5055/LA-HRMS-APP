import 'package:flutter/material.dart';

class TimeOffScreen extends StatelessWidget {
  const TimeOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Off'),
        backgroundColor: const Color(0xFF00AEEF),
      ),
      body: const Center(
        child: Text('Time Off Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
