import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _appKey;
  int? _employeeId;
  List<Map<String, dynamic>> _shifts = [];
  String _filterStatus = 'all';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _appKey = await StorageService.getAppKey();
    _employeeId = await StorageService.getEmployeeId();

    if (_appKey != null && _employeeId != null) {
      await _loadShifts();
    }

    setState(() => _isLoading = false);
    _animationController.forward(from: 0);
  }

  Future<void> _loadShifts() async {
    final result = await ApiService.getAllShifts(_appKey!, _employeeId!);

    if (result['success'] == true) {
      setState(() {
        _shifts = List<Map<String, dynamic>>.from(result['shifts'] ?? []);
      });
    }
  }

  List<Map<String, dynamic>> get _filteredShifts {
    if (_filterStatus == 'all') return _shifts;
    return _shifts.where((shift) {
      final status = (shift['status'] ?? '').toString().toLowerCase();
      return status == _filterStatus.toLowerCase();
    }).toList();
  }

  Map<String, int> get _statistics {
    int present = 0, absent = 0, leave = 0;
    for (var shift in _shifts) {
      final status = (shift['status'] ?? '').toString().toLowerCase();
      if (status == 'present') {
        present++;
      } else if (status == 'absent') absent++;
      else if (status == 'leave') leave++;
    }
    return {'present': present, 'absent': absent, 'leave': leave};
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final stats = _statistics;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                Container(
                  padding: EdgeInsets.all(isWeb ? 24 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Stats Grid
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isWeb ? 4 : (isTablet ? 4 : 2),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: isWeb ? 2 : 1.5,
                          children: [
                            _buildStatCard('Total', '${_shifts.length}', Icons.event_rounded, Colors.blue),
                            _buildStatCard('Present', '${stats['present']}', Icons.check_circle_rounded, Colors.green),
                            _buildStatCard('Absent', '${stats['absent']}', Icons.cancel_rounded, Colors.red),
                            _buildStatCard('Leave', '${stats['leave']}', Icons.event_busy_rounded, Colors.orange),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all', Icons.list_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip('Present', 'present', Icons.check_circle_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip('Absent', 'absent', Icons.cancel_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip('Leave', 'leave', Icons.event_busy_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Shifts List
                Expanded(
                  child: _filteredShifts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _shifts.isEmpty ? 'No shifts found' : 'No shifts match the filter',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: EdgeInsets.all(isWeb ? 24 : 16),
                            itemCount: _filteredShifts.length,
                            itemBuilder: (context, index) {
                              final shift = _filteredShifts[index];
                              return FadeTransition(
                                opacity: _animationController,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(_animationController),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                                    child: _buildShiftCard(shift, isWeb, isTablet),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    final color = _getFilterColor(value);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      elevation: isSelected ? 4 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'leave': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Widget _buildShiftCard(Map<String, dynamic> shift, bool isWeb, bool isTablet) {
    final status = shift['status'] ?? 'unknown';
    final color = _getStatusColor(status);
    final hasCheckIn = shift['check_in_time'] != false && shift['check_in_time'] != null;
    final hasCheckOut = shift['check_out_time'] != false && shift['check_out_time'] != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDayOfWeek(shift['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Shift Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Shift Time',
                      '${shift['start_time']} - ${shift['end_time']}',
                      Icons.schedule_rounded,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              if (hasCheckIn || hasCheckOut) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (hasCheckIn)
                      Expanded(
                        child: _buildInfoItem(
                          'Check-in',
                          shift['check_in_time'].toString(),
                          Icons.login_rounded,
                          Colors.green,
                        ),
                      ),
                    if (hasCheckIn && hasCheckOut) const SizedBox(width: 12),
                    if (hasCheckOut)
                      Expanded(
                        child: _buildInfoItem(
                          'Check-out',
                          shift['check_out_time'].toString(),
                          Icons.logout_rounded,
                          Colors.red,
                        ),
                      ),
                  ],
                ),
              ],

              // Working Hours if available
              if (shift['worked_hours'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_rounded, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Worked: ${shift['worked_hours']} hours',
                        style: TextStyle(
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'leave': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Icons.check_circle_rounded;
      case 'absent': return Icons.cancel_rounded;
      case 'leave': return Icons.event_busy_rounded;
      default: return Icons.help_rounded;
    }
  }

  String _getDayOfWeek(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }
}