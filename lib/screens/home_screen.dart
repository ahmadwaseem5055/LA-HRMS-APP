import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'attendance_screen.dart';
import 'payroll_screen.dart';
import 'timesheet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCheckedIn = false;
  bool _onBreak = false;
  String? _employeeName;
  String? _department;
  String? _appKey;
  int? _employeeId;

  int _assignedShifts = 0;
  int _attendedShifts = 0;
  int _missedShifts = 0;
  double _workedHours = 0;
  double _attendancePercentage = 0;

  bool _hasShift = false;
  String? _shiftStart;
  String? _shiftEnd;
  String? _attendanceStatus;
  bool _isShiftCompleted = false;

  List<Map<String, dynamic>> _breakTypes = [];
  int? _currentBreakTypeId;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _employeeName = await StorageService.getEmployeeName();
    _department = await StorageService.getDepartment();

    if (_appKey != null && _employeeId != null) {
      await Future.wait([
        _loadTodayShift(),
        _loadDashboard(),
        _loadBreakTypes(),
      ]);
    }

    setState(() => _isLoading = false);
    _animationController.forward();
  }

  Future<void> _loadTodayShift() async {
    final result = await ApiService.getTodayShift(_appKey!, _employeeId!);

    if (result['success'] == true && result['shift_found'] == true) {
      setState(() {
        _hasShift = true;
        _shiftStart = result['shift_start'];
        _shiftEnd = result['shift_end'];
        _attendanceStatus = result['attendance_status'];
        
        _isShiftCompleted = _attendanceStatus == 'completed';
        
        if (_isShiftCompleted) {
          _isCheckedIn = false;
        } else {
          _isCheckedIn = _attendanceStatus == 'checked_in';
        }
      });
    }
  }

  Future<void> _loadDashboard() async {
    final result = await ApiService.getDashboard(
      _appKey!,
      _employeeId!,
      type: 'monthly',
      month: DateTime.now().toString().substring(0, 7),
    );

    if (result['success'] == true) {
      setState(() {
        _assignedShifts = result['assigned_shifts'] ?? 0;
        _attendedShifts = result['attended_shifts'] ?? 0;
        _missedShifts = result['missed_shifts'] ?? 0;
        _workedHours = (result['worked_hours'] ?? 0).toDouble();
        _attendancePercentage = (result['attendance_percentage'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _loadBreakTypes() async {
    final result = await ApiService.getBreakTypes(_appKey!);

    if (result['success'] == true) {
      setState(() {
        _breakTypes = List<Map<String, dynamic>>.from(result['break_types'] ?? []);
      });
    }
  }

  Future<void> _handleCheckIn() async {
    if (_appKey == null || _employeeId == null) return;

    final result = await ApiService.checkIn(_appKey!, _employeeId!);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Checked in at ${result['check_in_time']}'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result['error'] ?? 'Check-in failed')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    if (_appKey == null || _employeeId == null) return;

    final result = await ApiService.checkOut(_appKey!, _employeeId!);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Checked out • ${result['worked_hours']} hrs worked'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result['error'] ?? 'Check-out failed')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleStartBreak() async {
    if (_breakTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No break types available')),
      );
      return;
    }

    final selectedBreak = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Break Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _breakTypes.map((breakType) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  breakType['paid'] ? Icons.coffee : Icons.lunch_dining,
                  color: Colors.blue.shade700,
                ),
                title: Text(breakType['name']),
                subtitle: Text(breakType['paid'] ? 'Paid break' : 'Unpaid break'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pop(context, breakType),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedBreak == null) return;

    final result = await ApiService.startBreak(
      _appKey!,
      _employeeId!,
      selectedBreak['id'],
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _onBreak = true;
        _currentBreakTypeId = selectedBreak['id'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.pause_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Started ${selectedBreak['name']} break'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result['error'] ?? 'Failed to start break')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleEndBreak() async {
    final result = await ApiService.endBreak(_appKey!, _employeeId!);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _onBreak = false;
        _currentBreakTypeId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Break ended • ${result['duration_minutes']} min'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(result['error'] ?? 'Failed to end break')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
      drawer: isWeb ? null : _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (isWeb)
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: _buildDrawerContent(),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isWeb ? 32 : (isTablet ? 24 : 16)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeCard(isWeb, isTablet),
                            const SizedBox(height: 24),
                            if (_hasShift) ...[
                              _buildShiftCard(isWeb, isTablet),
                              const SizedBox(height: 24),
                            ],
                            _buildAttendanceControls(isWeb, isTablet),
                            const SizedBox(height: 24),
                            _buildStatsGrid(isWeb, isTablet),
                            const SizedBox(height: 24),
                            _buildQuickActions(isWeb, isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWelcomeCard(bool isWeb, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: CircleAvatar(
                radius: isWeb ? 40 : 32,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(_employeeName),
                  style: TextStyle(
                    fontSize: isWeb ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(width: isWeb ? 24 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isWeb ? 16 : 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _employeeName ?? 'Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWeb ? 26 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _department ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isWeb)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_attendancePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Attendance',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftCard(bool isWeb, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.schedule_rounded, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Today\'s Shift',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_attendanceStatus!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_attendanceStatus!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildShiftTimeItem('Start Time', _shiftStart ?? '', Icons.login),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShiftTimeItem('End Time', _shiftEnd ?? '', Icons.logout),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTimeItem(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceControls(bool isWeb, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_isShiftCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Today\'s shift is already completed',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Check In',
                      Icons.login_rounded,
                      Colors.green,
                      _isCheckedIn ? null : _handleCheckIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Check Out',
                      Icons.logout_rounded,
                      Colors.red,
                      _isCheckedIn ? _handleCheckOut : null,
                    ),
                  ),
                ],
              ),
              if (_isCheckedIn) ...[
                const SizedBox(height: 12),
                _buildActionButton(
                  _onBreak ? 'End Break' : 'Start Break',
                  _onBreak ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  _onBreak ? Colors.green : Colors.orange,
                  _onBreak ? _handleEndBreak : _handleStartBreak,
                  fullWidth: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onPressed, {bool fullWidth = false}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isWeb, bool isTablet) {
    final crossAxisCount = isWeb ? 4 : (isTablet ? 4 : 2);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isWeb ? 1.5 : 1.2,
      children: [
        _buildStatCard('Assigned Shifts', '$_assignedShifts', Icons.event_rounded, Colors.blue),
        _buildStatCard('Attended', '$_attendedShifts', Icons.check_circle_rounded, Colors.green),
        _buildStatCard('Missed', '$_missedShifts', Icons.cancel_rounded, Colors.red),
        _buildStatCard('Hours Worked', _workedHours.toStringAsFixed(1), Icons.timer_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isWeb, bool isTablet) {
    final crossAxisCount = isWeb ? 5 : (isTablet ? 4 : 2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard('Attendance', Icons.list_alt_rounded, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
            }),
            _buildQuickActionCard('Timesheet', Icons.timer_outlined, Colors.teal, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TimesheetScreen()));
            }),
            _buildQuickActionCard('Leave', Icons.event_busy_rounded, Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen()));
            }),
            _buildQuickActionCard('Payroll', Icons.payments_rounded, Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen()));
            }),
            _buildQuickActionCard('Profile', Icons.person_rounded, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: _buildDrawerContent(),
    );
  }

  Widget _buildDrawerContent() {
    return Column(
      children: [
        UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
            ),
          ),
          currentAccountPicture: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _getInitials(_employeeName),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          accountName: Text(
            _employeeName ?? 'Employee',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          accountEmail: Text(_department ?? ''),
        ),
        _buildDrawerItem(Icons.dashboard_rounded, 'Dashboard', () => Navigator.pop(context)),
        _buildDrawerItem(Icons.fingerprint_rounded, 'Attendance', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
        }),
        _buildDrawerItem(Icons.timer_outlined, 'Timesheet', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TimesheetScreen()));
        }),
        _buildDrawerItem(Icons.calendar_today_rounded, 'Leave', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen()));
        }),
      
        _buildDrawerItem(Icons.payments_rounded, 'Payroll', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen()));
        }),
        _buildDrawerItem(Icons.person_rounded, 'Profile', () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }),
        const Divider(),
        _buildDrawerItem(Icons.logout_rounded, 'Logout', () async {
          await StorageService.logout();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
        }, color: Colors.red),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'E';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'checked_in': return Colors.green;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'checked_in': return 'Checked In';
      case 'completed': return 'Completed';
      case 'not_started': return 'Not Started';
      default: return status;
    }
  }
}