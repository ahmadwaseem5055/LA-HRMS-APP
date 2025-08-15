import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle base64 image - your API seems to provide double-encoded base64
    Widget profileWidget = const Icon(
      Icons.person,
      size: 60,
      color: Colors.white,
    );

    if (userData['image'] != null && userData['image'].isNotEmpty) {
      try {
        String imageData = userData['image'].toString();
        
        // First decode to get the actual base64 image data
        String decodedImageData = utf8.decode(base64Decode(imageData));
        
        // Check if it's an SVG (common for profile images)
        if (decodedImageData.contains('<svg')) {
          // For SVG, we'll show the default icon since flutter doesn't support SVG natively
          print("🔹 SVG image detected, using default icon");
          profileWidget = const Icon(
            Icons.person,
            size: 60,
            color: Colors.white,
          );
        } else {
          // Try to extract base64 image data if it's embedded
          RegExp base64Pattern = RegExp(r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)');
          Match? match = base64Pattern.firstMatch(decodedImageData);
          
          if (match != null) {
            String actualImageBase64 = match.group(1)!;
            profileWidget = ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.memory(
                base64Decode(actualImageBase64),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("❌ Error displaying image: $error");
                  return const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  );
                },
              ),
            );
          }
        }
      } catch (e) {
        print("❌ Error processing image: $e");
        profileWidget = const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        );
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: profileWidget,
          ),
          
          const SizedBox(height: 30),
          
          // Profile Info Cards
          _buildInfoCard(
            icon: Icons.badge,
            title: 'Employee ID',
            value: userData['employee_id']?.toString() ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.person,
            title: 'Name',
            value: userData['employee_name'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.email,
            title: 'Email',
            value: userData['email'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.work,
            title: 'Department',
            value: userData['department'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.phone,
            title: 'Mobile',
            value: userData['mobile'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.business,
            title: 'Company',
            value: userData['company'] ?? 'N/A',
          ),
          
          // Additional info card for success status (optional)
          if (userData['success'] == true)
            _buildInfoCard(
              icon: Icons.verified,
              title: 'Status',
              value: 'Verified Account',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF667eea),
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}