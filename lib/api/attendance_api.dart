import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceApi {
  final String baseUrl = "https://lahoreanalytica-la1-uat-20891347.dev.odoo.com";

  Future<Map<String, dynamic>?> checkIn(int employeeId) async {
    // Create the URL for check-in with date parameter to ensure server-side date validation
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final url = Uri.parse("$baseUrl/api/attendance/checkin?employee_id=$employeeId&date=$today");

    print("🔹 POST request to: $url");

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "employee_id": employeeId,
          "date": today,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
      
      // If not successful, return the response for error handling
      if (res.statusCode != 200) {
        final errorData = json.decode(res.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'Check-in failed',
          'statusCode': res.statusCode
        };
      }
    } catch (e) {
      print("❌ Check-in error: $e");
      return {
        'status': 'error',
        'message': 'Network error: $e'
      };
    }

    return null;
  }

  Future<Map<String, dynamic>?> checkOut(int employeeId) async {
    // Create the URL for check-out with date parameter
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final url = Uri.parse("$baseUrl/api/attendance/checkout?employee_id=$employeeId&date=$today");

    print("🔹 POST request to: $url");

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "employee_id": employeeId,
          "date": today,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
      
      // If not successful, return the response for error handling
      if (res.statusCode != 200) {
        final errorData = json.decode(res.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'Check-out failed',
          'statusCode': res.statusCode
        };
      }
    } catch (e) {
      print("❌ Check-out error: $e");
      return {
        'status': 'error',
        'message': 'Network error: $e'
      };
    }

    return null;
  }

  Future<Map<String, dynamic>?> getAttendanceById(int attendanceId) async {
    // Get attendance details by attendance ID
    final url = Uri.parse("$baseUrl/api/attendance/details?attendance_id=$attendanceId");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print("❌ Get attendance details error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> getCurrentAttendanceStatus(int employeeId) async {
    // Get current attendance status for the employee with today's date
    final today = DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse("$baseUrl/api/attendance/status?employee_id=$employeeId&date=$today");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print("❌ Get attendance status error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> getTodayAttendance(int employeeId) async {
    // Get today's attendance for the employee with explicit date parameter
    final today = DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse("$baseUrl/api/attendance/today?employee_id=$employeeId&date=$today");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          // Validate that the returned data is actually for today
          final attendanceData = data['data'];
          if (attendanceData != null) {
            final checkInTime = attendanceData['check_in'] ?? attendanceData['check_in_time'];
            if (checkInTime != null) {
              try {
                final checkInDate = DateTime.parse(checkInTime);
                final checkInDateStr = '${checkInDate.year}-${checkInDate.month.toString().padLeft(2, '0')}-${checkInDate.day.toString().padLeft(2, '0')}';
                
                // Only return data if it's actually from today
                if (checkInDateStr == today) {
                  return data;
                } else {
                  // Data is from a different day, return null
                  print("🔹 Attendance data is from $checkInDateStr, not today ($today)");
                  return {
                    'success': true,
                    'data': null,
                    'message': 'No attendance record for today'
                  };
                }
              } catch (e) {
                print("❌ Error parsing check-in date: $e");
                return data; // Return as-is if we can't parse the date
              }
            }
          }
          return data;
        }
      }
    } catch (e) {
      print("❌ Get today's attendance error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> getAttendanceHistory(int employeeId, {int? days}) async {
    // Get attendance history for the employee
    final params = <String, String>{
      'employee_id': employeeId.toString(),
    };
    
    if (days != null) {
      params['days'] = days.toString();
    }
    
    final url = Uri.parse("$baseUrl/api/attendance/history").replace(queryParameters: params);

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print("❌ Get attendance history error: $e");
    }

    return null;
  }

  // Additional method to validate if employee can check in
  Future<Map<String, dynamic>?> canCheckIn(int employeeId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse("$baseUrl/api/attendance/can-checkin?employee_id=$employeeId&date=$today");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data;
      }
    } catch (e) {
      print("❌ Can check-in validation error: $e");
    }

    return null;
  }

  // Additional method to validate if employee can check out
  Future<Map<String, dynamic>?> canCheckOut(int employeeId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final url = Uri.parse("$baseUrl/api/attendance/can-checkout?employee_id=$employeeId&date=$today");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data;
      }
    } catch (e) {
      print("❌ Can check-out validation error: $e");
    }

    return null;
  }

  // Method to get attendance for a specific date
  Future<Map<String, dynamic>?> getAttendanceForDate(int employeeId, String date) async {
    final url = Uri.parse("$baseUrl/api/attendance/date?employee_id=$employeeId&date=$date");

    print("🔹 GET request to: $url");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print("❌ Get attendance for date error: $e");
    }

    return null;
  }
}