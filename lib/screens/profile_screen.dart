import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const ProfileScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    String? base64Image =
        employee["image_1920"] != null && employee["image_1920"] is String
            ? employee["image_1920"]
            : null;

    String name = employee["name"] ?? "";
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : "Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade200,
              backgroundImage:
                  base64Image != null ? MemoryImage(base64Decode(base64Image)) : null,
              child: base64Image == null
                  ? Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text("Name: $name", style: const TextStyle(fontSize: 18)),
            Text("Email: ${employee["work_email"] ?? "-"}"),
            Text("Job Title: ${employee["job_title"] ?? "-"}"),
            Text("Phone: ${employee["work_phone"] ?? "-"}"),
          ],
        ),
      ),
    );
  }
}
