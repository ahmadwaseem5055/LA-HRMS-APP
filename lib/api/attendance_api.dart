import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceApi {
  final String baseUrl = "https://lahoreanalytica-la1-uat-20891347.dev.odoo.com";

  Future<Map<String, dynamic>?> checkIn(int employeeId) async {
    // Create the URL for check-in
    final url = Uri.parse("$baseUrl/api/attendance/checkin?employee_id=$employeeId");

    print("🔹 POST request to: $url");

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      print("❌ Check-in error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> checkOut(int employeeId) async {
    // Create the URL for check-out
    final url = Uri.parse("$baseUrl/api/attendance/checkout?employee_id=$employeeId");

    print("🔹 POST request to: $url");

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      print("🔹 Status code: ${res.statusCode}");
      print("🔹 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      print("❌ Check-out error: $e");
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
    // Get current attendance status for the employee
    final url = Uri.parse("$baseUrl/api/attendance/status?employee_id=$employeeId");

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
    // Get today's attendance for the employee
    final url = Uri.parse("$baseUrl/api/attendance/today?employee_id=$employeeId");

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
      print("❌ Get today's attendance error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> getAttendanceHistory(int employeeId) async {
    // Get attendance history for the employee
    final url = Uri.parse("$baseUrl/api/attendance/history?employee_id=$employeeId");

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
}