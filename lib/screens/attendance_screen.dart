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

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isCheckedIn = false;
  String checkInTime = '--:--';
  String checkOutTime = '--:--';
  bool isLoading = false;

  final AttendanceApi attendanceApi = AttendanceApi();
  int? currentAttendanceId;

  @override
  void initState() {
    super.initState();
    _initializeAttendanceState();
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

  // UPDATED: Converts all API timestamps to Pakistan Time correctly
  String _formatTimeFromApi(String apiTime) {
    try {
      DateTime dateTime = DateTime.parse(apiTime).toUtc().add(const Duration(hours: 5));
      int hour = dateTime.hour % 12;
      if (hour == 0) hour = 12;
      String minute = dateTime.minute.toString().padLeft(2, '0');
      String period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      debugPrint('Error formatting API time: $e');
      if (apiTime.contains('T') && apiTime.length > 16) {
        try {
          return apiTime.substring(11, 16);
        } catch (e2) {
          debugPrint('Error extracting time part: $e2');
        }
      }
      return apiTime;
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: checkOutTime != '--:--'
                    ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]
                    : (isCheckedIn
                        ? [const Color(0xFF56ab2f), const Color(0xFFa8e6cf)]
                        : [const Color(0xFFff9a9e), const Color(0xFFfecfef)]),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isCheckedIn ? Colors.green : Colors.pink).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  checkOutTime != '--:--'
                      ? Icons.check_circle
                      : (isCheckedIn ? Icons.work : Icons.home),
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 15),
                Text(
                  checkOutTime != '--:--'
                      ? "Day Completed"
                      : (isCheckedIn ? "You're Checked In" : "You're Checked Out"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTimeCard('Check In', checkInTime),
                    _buildTimeCard('Check Out', checkOutTime),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: buttonEnabled ? _toggleCheckIn : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonEnabled ? Colors.white : Colors.grey[300],
                      foregroundColor: checkOutTime != '--:--'
                          ? Colors.grey
                          : (isCheckedIn ? Colors.red : Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: buttonEnabled ? 5 : 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Days Present', '4', Colors.green),
                    _buildSummaryItem('Hours Worked', '32', Colors.blue),
                    _buildSummaryItem('On Time', '3', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 15),
                _buildAttendanceItem(
                  'Today',
                  checkInTime != '--:--'
                      ? (checkOutTime != '--:--'
                          ? '$checkInTime - $checkOutTime'
                          : '$checkInTime - In Progress')
                      : 'Not Checked In',
                  isCheckedIn
                      ? (checkOutTime != '--:--' ? Colors.green : Colors.orange)
                      : (checkOutTime != '--:--' ? Colors.green : Colors.red),
                ),
                _buildAttendanceItem('Yesterday', '08:45 AM - 05:30 PM', Colors.green),
                _buildAttendanceItem('Dec 9, 2024', '09:15 AM - 05:45 PM', Colors.green),
                _buildAttendanceItem('Dec 8, 2024', 'Weekend', Colors.grey),
                _buildAttendanceItem('Dec 7, 2024', '08:30 AM - 05:15 PM', Colors.green),
                _buildAttendanceItem('Dec 6, 2024', '09:45 AM - 06:00 PM', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(String date, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF333333),
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}