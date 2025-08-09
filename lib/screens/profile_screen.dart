import 'dart:convert';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  // Make `employee` optional and default to an empty map so
  // ProfileScreen() can be called without arguments.
  const ProfileScreen({Key? key, Map<String, dynamic>? employee})
      : employee = employee ?? const {},
        super(key: key);

  // Show Logout Confirmation
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              "Logout",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Are you sure you want to sign out?",
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 380;

    String? base64Image =
        employee["image_1920"] != null && employee["image_1920"] is String
            ? employee["image_1920"]
            : null;

    String name = employee["name"] ?? "";
    String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, name),
              const SizedBox(height: 20),
              _buildProfileContent(isSmallScreen, base64Image, firstLetter, name),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER WITH NAME + LOGOUT
  Widget _buildHeader(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello,",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                name.split(' ').first.isNotEmpty ? name.split(' ').first : "Employee",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // MAIN PROFILE CONTENT
  Widget _buildProfileContent(bool isSmallScreen, String? base64Image, String firstLetter, String name) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileCard(isSmallScreen, base64Image, firstLetter, name),
              const SizedBox(height: 25),
              Expanded(child: _buildInfoGrid(isSmallScreen)),
            ],
          ),
        ),
      ),
    );
  }

  // PROFILE CARD
  Widget _buildProfileCard(bool isSmallScreen, String? base64Image, String firstLetter, String name) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    radius: isSmallScreen ? 45 : 50,
                    backgroundColor: Colors.white,
                    backgroundImage: base64Image != null ? MemoryImage(base64Decode(base64Image)) : null,
                    child: base64Image == null
                        ? Text(firstLetter,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 36 : 40,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF667eea),
                            ))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.1)
                ]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                employee["job_title"] ?? "Employee",
                style: const TextStyle(fontSize: 14, color: Color(0xFF667eea), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INFO GRID
  Widget _buildInfoGrid(bool isSmallScreen) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: isSmallScreen ? 1.0 : 1.1,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildModernInfoCard(Icons.alternate_email_rounded, "Email", employee["work_email"] ?? "Not provided",
            const Color(0xFFFF6B6B), [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]),
        _buildModernInfoCard(Icons.phone_rounded, "Work Phone", employee["work_phone"] ?? "Not provided",
            const Color(0xFF4ECDC4), [const Color(0xFF4ECDC4), const Color(0xFF7BDBD6)]),
        _buildModernInfoCard(Icons.smartphone_rounded, "Mobile", employee["mobile_phone"] ?? "Not provided",
            const Color(0xFF45B7D1), [const Color(0xFF45B7D1), const Color(0xFF73C5DA)]),
        _buildModernInfoCard(Icons.domain_rounded, "Department", employee["department"] ?? "Not assigned",
            const Color(0xFF96CEB4), [const Color(0xFF96CEB4), const Color(0xFFB5D6C6)]),
        _buildModernInfoCard(Icons.work_outline_rounded, "Position",
            employee["job_position"] ?? employee["job_title"] ?? "Not assigned", const Color(0xFFFECA57),
            [const Color(0xFFFECA57), const Color(0xFFFFD77A)]),
        _buildModernInfoCard(Icons.supervisor_account_rounded, "Manager", employee["manager"] ?? "Not assigned",
            const Color(0xFFFF9FF3), [const Color(0xFFFF9FF3), const Color(0xFFFFB3F5)]),
      ],
    );
  }

  // INFO CARD WIDGET
  Widget _buildModernInfoCard(IconData icon, String title, String value, Color color, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                _formatValue(value, title),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w700, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FORMAT VALUE FOR DISPLAY
  String _formatValue(String value, String title) {
    if (title == "Email" && value.contains('@')) {
      var parts = value.split('@');
      var local = parts[0];
      var domain = parts[1];
      if (local.length > 8) local = local.substring(0, 8) + '..';
      return '$local@$domain';
    }
    if (value.length > 15 && ["Manager", "Position", "Department"].contains(title)) {
      return value.substring(0, 12) + '...';
    }
    return value;
  }
}
