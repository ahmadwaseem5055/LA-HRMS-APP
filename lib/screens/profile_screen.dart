import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  ProfileScreen({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(employee["name"] ?? "Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${employee["name"] ?? ""}"),
            Text("Email: ${employee["work_email"] ?? "-"}"),
            Text("Job Title: ${employee["job_title"] ?? "-"}"),
            Text("Phone: ${employee["work_phone"] ?? "-"}"),
          ],
        ),
      ),
    );
  }
}
