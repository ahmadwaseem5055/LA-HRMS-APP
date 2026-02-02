import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _appKey;
  int? _employeeId;
  
  String? _employeeName;
  String? _email;
  String? _department;
  String? _mobile;
  String? _company;
  String? _jobTitle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _appKey = await StorageService.getAppKey();
    _employeeId = await StorageService.getEmployeeId();
    _employeeName = await StorageService.getEmployeeName();
    _email = await StorageService.getEmployeeEmail();
    _department = await StorageService.getDepartment();
    _company = await StorageService.getCompany();
    _jobTitle = await StorageService.getJobPosition();
    
    setState(() => _isLoading = false);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'E';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: isWeb ? 300 : (isTablet ? 250 : 200),
                  pinned: true,
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade700,
                            Colors.blue.shade900,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isWeb ? 60 : (isTablet ? 50 : 40)),
                            Container(
                              width: isWeb ? 140 : (isTablet ? 120 : 100),
                              height: isWeb ? 140 : (isTablet ? 120 : 100),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(_employeeName),
                                  style: TextStyle(
                                    fontSize: isWeb ? 56 : (isTablet ? 48 : 40),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isWeb ? 20 : (isTablet ? 16 : 12)),
                            Text(
                              _employeeName ?? 'Employee',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWeb ? 32 : (isTablet ? 28 : 24),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _jobTitle ?? _department ?? '',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isWeb ? 20 : (isTablet ? 18 : 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isWeb ? 1200 : double.infinity,
                      ),
                      padding: EdgeInsets.all(isWeb ? 40 : (isTablet ? 32 : 16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: isWeb ? 28 : (isTablet ? 24 : 20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isWeb ? 24 : (isTablet ? 20 : 16)),
                          
                          _buildPersonalInfoGrid(isWeb, isTablet),
                          
                          SizedBox(height: isWeb ? 40 : (isTablet ? 32 : 24)),
                          SizedBox(
                            width: double.infinity,
                            height: isWeb ? 60 : (isTablet ? 56 : 50),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await StorageService.logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              icon: Icon(Icons.logout, size: isWeb ? 24 : 20),
                              label: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: isWeb ? 20 : (isTablet ? 18 : 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isWeb ? 24 : (isTablet ? 20 : 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalInfoGrid(bool isWeb, bool isTablet) {
    final infoItems = [
      {
        'icon': Icons.email,
        'label': 'Email',
        'value': _email ?? 'N/A',
        'color': Colors.blue,
      },
      {
        'icon': Icons.business,
        'label': 'Department',
        'value': _department ?? 'N/A',
        'color': Colors.purple,
      },
      {
        'icon': Icons.business_center,
        'label': 'Company',
        'value': _company ?? 'N/A',
        'color': Colors.orange,
      },
      {
        'icon': Icons.work,
        'label': 'Job Position',
        'value': _jobTitle ?? 'N/A',
        'color': Colors.green,
      },
    ];

    if (isWeb || isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: isWeb ? 20 : 16,
          crossAxisSpacing: isWeb ? 20 : 16,
          childAspectRatio: isWeb ? 3 : 2.5,
        ),
        itemCount: infoItems.length,
        itemBuilder: (context, index) {
          final item = infoItems[index];
          return _buildInfoCard(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            value: item['value'] as String,
            color: item['color'] as Color,
            isWeb: isWeb,
            isTablet: isTablet,
          );
        },
      );
    } else {
      return Column(
        children: infoItems.map((item) {
          return _buildInfoCard(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            value: item['value'] as String,
            color: item['color'] as Color,
            isWeb: isWeb,
            isTablet: isTablet,
          );
        }).toList(),
      );
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isWeb,
    required bool isTablet,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: (isWeb || isTablet) ? 0 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 24 : (isTablet ? 20 : 16),
          vertical: isWeb ? 20 : (isTablet ? 18 : 12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isWeb ? 14 : (isTablet ? 12 : 10)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isWeb ? 32 : (isTablet ? 28 : 24),
              ),
            ),
            SizedBox(width: isWeb ? 20 : (isTablet ? 16 : 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isWeb ? 15 : (isTablet ? 14 : 12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isWeb ? 20 : (isTablet ? 18 : 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}