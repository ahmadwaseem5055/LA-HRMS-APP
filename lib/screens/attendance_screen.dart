// NOTE: Add this dependency to your pubspec.yaml:
// dependencies:
//   shared_preferences: ^2.2.2

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/attendance_api.dart';

class AttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AttendanceScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> 
    with SingleTickerProviderStateMixin {
  bool isCheckedIn = false;
  String checkInTime = '--:--';
  String checkOutTime = '--:--';
  bool isLoading = false;

  final AttendanceApi attendanceApi = AttendanceApi();
  int? currentAttendanceId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAttendanceState();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get gradient colors consistent with profile
  List<Color> _getGradientColors() {
    String firstLetter = _getFirstLetter(widget.userData['employee_name']);
    const gradients = [
      [Color(0xFF667eea), Color(0xFF764ba2)],
      
    ];
    
    int index = firstLetter.codeUnitAt(0) % gradients.length;
    return gradients[index];
  }

  String _getFirstLetter(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name.trim().split(' ').first[0].toUpperCase();
  }

  Future<void> _initializeAttendanceState() async {
    int? employeeId = _getEmployeeId();
    if (employeeId == null) return;

    await _loadLocalAttendanceState(employeeId);
    await _syncWithApi(employeeId);
  }

  Future<void> _loadLocalAttendanceState(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'attendance_user_$employeeId';

      final isLocalCheckedIn = prefs.getBool('${userKey}_isCheckedIn') ?? false;
      final localCheckInTime = prefs.getString('${userKey}_checkInTime') ?? '--:--';
      final localCheckOutTime = prefs.getString('${userKey}_checkOutTime') ?? '--:--';
      final localAttendanceId = prefs.getInt('${userKey}_attendanceId');
      final localDate = prefs.getString('${userKey}_date') ?? '';

      final today = _getTodayDateString();

      if (localDate == today) {
        setState(() {
          isCheckedIn = isLocalCheckedIn;
          checkInTime = localCheckInTime;
          checkOutTime = localCheckOutTime;
          currentAttendanceId = localAttendanceId;
        });
      } else {
        await _clearLocalAttendanceState(employeeId);
      }
    } catch (e) {
      debugPrint('Error loading local attendance state: $e');
    }
  }

  Future<void> _saveLocalAttendanceState(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'attendance_user_$employeeId';
      final today = _getTodayDateString();

      await prefs.setBool('${userKey}_isCheckedIn', isCheckedIn);
      await prefs.setString('${userKey}_checkInTime', checkInTime);
      await prefs.setString('${userKey}_checkOutTime', checkOutTime);
      await prefs.setString('${userKey}_date', today);

      if (currentAttendanceId != null) {
        await prefs.setInt('${userKey}_attendanceId', currentAttendanceId!);
      }
    } catch (e) {
      debugPrint('Error saving local attendance state: $e');
    }
  }

  Future<void> _clearLocalAttendanceState(int employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'attendance_user_$employeeId';

      await prefs.remove('${userKey}_isCheckedIn');
      await prefs.remove('${userKey}_checkInTime');
      await prefs.remove('${userKey}_checkOutTime');
      await prefs.remove('${userKey}_attendanceId');
      await prefs.remove('${userKey}_date');

      setState(() {
        isCheckedIn = false;
        checkInTime = '--:--';
        checkOutTime = '--:--';
        currentAttendanceId = null;
      });
    } catch (e) {
      debugPrint('Error clearing local attendance state: $e');
    }
  }

  // Helper method to get today's date string in Pakistan Time
  String _getTodayDateString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _syncWithApi(int employeeId) async {
    try {
      final todayResult = await attendanceApi.getTodayAttendance(employeeId);

      if (todayResult != null && todayResult['success'] == true) {
        final attendanceData = todayResult['data'];

        if (attendanceData != null) {
          final apiCheckInTime = attendanceData['check_in'] ?? attendanceData['check_in_time'];
          final apiCheckOutTime = attendanceData['check_out'] ?? attendanceData['check_out_time'];
          final apiAttendanceId = attendanceData['attendance_id'] ?? attendanceData['id'];

          final today = _getTodayDateString();
          String? apiDateString;

          if (apiCheckInTime != null) {
            try {
              final apiDate = DateTime.parse(apiCheckInTime).toUtc().add(const Duration(hours: 5));
              apiDateString = '${apiDate.year}-${apiDate.month.toString().padLeft(2, '0')}-${apiDate.day.toString().padLeft(2, '0')}';
            } catch (e) {
              debugPrint('Error parsing API date: $e');
            }
          }

          if (apiDateString == today) {
            bool apiIsCheckedIn = apiCheckOutTime == null;
            bool needsUpdate = false;

            if (apiCheckInTime != null && checkInTime == '--:--') {
              setState(() {
                checkInTime = _formatTimeFromApi(apiCheckInTime);
                isCheckedIn = apiIsCheckedIn;
                currentAttendanceId = apiAttendanceId;
              });
              needsUpdate = true;
            }

            if (apiCheckOutTime != null && checkOutTime == '--:--') {
              setState(() {
                checkOutTime = _formatTimeFromApi(apiCheckOutTime);
                isCheckedIn = false;
              });
              needsUpdate = true;
            }

            if (needsUpdate) {
              await _saveLocalAttendanceState(employeeId);
            }
          } else {
            await _clearLocalAttendanceState(employeeId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing with API: $e');
    }
  }

  int? _getEmployeeId() {
    if (widget.userData['employee_id'] != null) {
      return int.tryParse(widget.userData['employee_id'].toString());
    } else if (widget.userData['id'] != null) {
      return int.tryParse(widget.userData['id'].toString());
    } else if (widget.userData['user_id'] != null) {
      return int.tryParse(widget.userData['user_id'].toString());
    } else if (widget.userData['data'] != null && widget.userData['data']['employee_id'] != null) {
      return int.tryParse(widget.userData['data']['employee_id'].toString());
    } else if (widget.userData['data'] != null && widget.userData['data']['id'] != null) {
      return int.tryParse(widget.userData['data']['id'].toString());
    }
    return null;
  }

  void _toggleCheckIn() async {
    int? employeeId = _getEmployeeId();
    if (employeeId == null) {
      _showErrorDialog('Employee ID not found. Please login again.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic>? result;

      if (!isCheckedIn && checkOutTime == '--:--') {
        final currentStatus = await attendanceApi.getCurrentAttendanceStatus(employeeId);
        if (currentStatus != null && currentStatus['success'] == true) {
          final statusData = currentStatus['data'];
          if (statusData != null && statusData['is_checked_in'] == true) {
            _showErrorDialog('You are already checked in. Please check out first.');
            setState(() {
              isLoading = false;
            });
            return;
          }
        }

        result = await attendanceApi.checkIn(employeeId);

        if (result != null && result['status'] == 'success') {
          currentAttendanceId = result['id'];
          String formattedTime = _formatTimeFromApi(result['check_in_time']);

          setState(() {
            isCheckedIn = true;
            checkInTime = formattedTime;
            checkOutTime = '--:--';
          });

          await _saveLocalAttendanceState(employeeId);
          _showSuccessDialog('Checked In Successfully!', 'You have successfully checked in at $checkInTime');
        } else {
          String errorMessage = result?['message'] ?? 'Failed to check in. Please try again.';
          _showErrorDialog(errorMessage);
        }
      } else if (isCheckedIn && checkOutTime == '--:--') {
        if (currentAttendanceId == null) {
          _showErrorDialog('No active attendance found. Please check in first.');
          setState(() {
            isLoading = false;
          });
          return;
        }

        result = await attendanceApi.checkOut(employeeId);

        if (result != null && result['status'] == 'success') {
          String formattedTime = _formatTimeFromApi(result['check_out_time']);

          setState(() {
            checkOutTime = formattedTime;
            isCheckedIn = false;
          });

          await _saveLocalAttendanceState(employeeId);
          _showSuccessDialog('Checked Out Successfully!', 'You have successfully checked out at $checkOutTime');
        } else {
          String errorMessage = result?['message'] ?? 'Failed to check out. Please try again.';
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      debugPrint('Error during check in/out: $e');
      _showErrorDialog('Network error. Please check your connection and try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // UPDATED: Extract time from your API format "15-08-2025 02:20 PM"
  String _formatTimeFromApi(String apiTime) {
    try {
      // Handle your API format: "15-08-2025 02:20 PM"
      if (apiTime.contains(' ') && (apiTime.contains('AM') || apiTime.contains('PM'))) {
        final parts = apiTime.split(' ');
        if (parts.length >= 3) {
          // Extract time and AM/PM parts
          final timePart = parts[1]; // "02:20"
          final periodPart = parts[2]; // "PM"
          return '$timePart $periodPart';
        }
      }
      
      // Fallback: Try ISO format parsing (existing logic)
      DateTime dateTime = DateTime.parse(apiTime).toUtc().add(const Duration(hours: 5));
      int hour = dateTime.hour % 12;
      if (hour == 0) hour = 12;
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      debugPrint('Error formatting API time: $e');
      
      // Final fallback: If it contains space, try to extract time part
      if (apiTime.contains(' ')) {
        try {
          final parts = apiTime.split(' ');
          // Look for time pattern (contains colon)
          for (String part in parts) {
            if (part.contains(':')) {
              // Check if next part is AM/PM
              int index = parts.indexOf(part);
              if (index + 1 < parts.length && (parts[index + 1] == 'AM' || parts[index + 1] == 'PM')) {
                return '${part} ${parts[index + 1]}';
              }
              return part; // Return just the time part
            }
          }
        } catch (e2) {
          debugPrint('Error extracting time part: $e2');
        }
      }
      
      // Ultimate fallback
      return apiTime.length > 10 ? apiTime.substring(0, 8) : apiTime;
    }
  }

  void _showSuccessDialog(String title, String message) {
    List<Color> gradientColors = _getGradientColors();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 20,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 20,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors = _getGradientColors();
    
    String buttonText;
    bool buttonEnabled = !isLoading;

    if (isCheckedIn && checkOutTime == '--:--') {
      buttonText = 'Check Out';
    } else if (checkOutTime != '--:--') {
      buttonText = 'Completed for Today';
      buttonEnabled = false;
    } else {
      buttonText = 'Check In';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Main Attendance Status Card
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: checkOutTime != '--:--'
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : (isCheckedIn
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : gradientColors),
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: (checkOutTime != '--:--'
                                ? const Color(0xFF10B981)
                                : (isCheckedIn ? const Color(0xFF3B82F6) : gradientColors[0]))
                            .withOpacity(0.4),
                        spreadRadius: 5,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        // Status Icon with Animation
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            checkOutTime != '--:--'
                                ? Icons.check_circle_rounded
                                : (isCheckedIn ? Icons.access_time_filled_rounded : Icons.schedule_rounded),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Status Text
                        Text(
                          checkOutTime != '--:--'
                              ? "Day Completed Successfully"
                              : (isCheckedIn ? "Currently Working" : "Ready to Start"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        Text(
                          checkOutTime != '--:--'
                              ? "Great job today!"
                              : (isCheckedIn 
                                  ? "You're checked in and ready to work" 
                                  : "Tap the button below to check in"),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Current Date Display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCurrentDate(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Time Display Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildEnhancedTimeCard('Check In', checkInTime, Icons.login_rounded),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildEnhancedTimeCard('Check Out', checkOutTime, Icons.logout_rounded),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Action Button
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: buttonEnabled
                                ? LinearGradient(
                                    colors: [Colors.white, Colors.white.withOpacity(0.9)],
                                  )
                                : null,
                            color: buttonEnabled ? null : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: buttonEnabled ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ] : null,
                          ),
                          child: ElevatedButton(
                            onPressed: buttonEnabled ? _toggleCheckIn : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: checkOutTime != '--:--'
                                  ? Colors.grey[600]
                                  : (isCheckedIn ? Colors.red[600] : gradientColors[0]),
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                                    ),
                                  )
                                                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          checkOutTime != '--:--'
                                              ? Icons.check_circle_rounded
                                              : (isCheckedIn ? Icons.logout_rounded : Icons.login_rounded),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            buttonText,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Recent Attendance Card
            _buildAnimatedCard(
              'Recent Attendance',
              Column(
                children: [
                  _buildAttendanceItem(
                    'Today',
                    checkInTime != '--:--'
                        ? (checkOutTime != '--:--'
                            ? '$checkInTime - $checkOutTime'
                            : '$checkInTime - In Progress')
                        : 'Not Checked In',
                    isCheckedIn
                        ? (checkOutTime != '--:--' ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                        : (checkOutTime != '--:--' ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    Icons.today_rounded,
                  ),
                  _buildAttendanceItem('Yesterday', '08:45 AM - 05:30 PM', const Color(0xFF10B981), Icons.check_circle_rounded),
                  _buildAttendanceItem('Dec 9, 2024', '09:15 AM - 05:45 PM', const Color(0xFF10B981), Icons.check_circle_rounded),
                  _buildAttendanceItem('Dec 8, 2024', 'Weekend', Colors.grey, Icons.weekend_rounded),
                  _buildAttendanceItem('Dec 7, 2024', '08:30 AM - 05:15 PM', const Color(0xFF10B981), Icons.check_circle_rounded),
                  _buildAttendanceItem('Dec 6, 2024', '09:45 AM - 06:00 PM', const Color(0xFFF59E0B), Icons.schedule_rounded),
                ],
              ),
              0,
              gradientColors,
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper method to get current date in a readable format
  String _getCurrentDate() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildEnhancedTimeCard(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time, // This now shows only time like "02:20 PM" instead of full date
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(String title, Widget content, int index, List<Color> gradientColors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.0, 0.3 + (index * 0.1)),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.4 + (index * 0.2),
              0.8 + (index * 0.1),
              curve: Curves.easeOutBack,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(String date, String time, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}