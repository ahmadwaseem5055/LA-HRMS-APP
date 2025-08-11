import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profile = userData['profile'] ?? {};
    
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
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
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
            value: profile['work_email'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.work,
            title: 'Designation',
            value: profile['job_title'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.business,
            title: 'Department',
            value: profile['department'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.phone,
            title: 'Phone',
            value: profile['phone'] ?? 'N/A',
          ),
          
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Location',
            value: profile['office_location'] ?? 'N/A',
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