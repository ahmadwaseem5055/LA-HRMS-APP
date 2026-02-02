import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://lahoreanalytica-la1-uat-25973349.dev.odoo.com';
  
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      print('=== API REQUEST ===');
      print('Endpoint: $endpoint');
      print('Body: $body');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        body: body.map((key, value) => MapEntry(key, value.toString())),
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'error': 'NETWORK_ERROR', 'detail': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> verifyLicense(String appKey) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/license/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'app_key': appKey}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data.containsKey('result') ? data['result'] : data;
      }
      
      return {'allowed': false, 'reason': 'SERVER_ERROR', 'detail': 'Status code: ${response.statusCode}'};
    } catch (e) {
      return {'allowed': false, 'reason': 'NETWORK_ERROR', 'detail': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> login(String appKey, String username, String password) async {
    return await _post('/api/login', {
      'app_key': appKey,
      'username': username,
      'password': password,
    });
  }
  
  static Future<Map<String, dynamic>> getTodayShift(String appKey, int employeeId) async {
    return await _post('/api/attendance/shift', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getAllShifts(String appKey, int employeeId) async {
    return await _post('/api/attendance/all_shifts', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> checkIn(String appKey, int employeeId) async {
    return await _post('/api/attendance/check_in', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> checkOut(String appKey, int employeeId) async {
    return await _post('/api/attendance/check_out', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getBreakTypes(String appKey) async {
    return await _post('/api/attendance/break_types', {'app_key': appKey});
  }
  
  static Future<Map<String, dynamic>> startBreak(String appKey, int employeeId, int breakTypeId) async {
    return await _post('/api/attendance/breaks/start', {
      'app_key': appKey,
      'employee_id': employeeId,
      'break_type_id': breakTypeId,
    });
  }
  
  static Future<Map<String, dynamic>> endBreak(String appKey, int employeeId) async {
    return await _post('/api/attendance/breaks/end', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getBreakHistory(String appKey, int employeeId) async {
    return await _post('/api/attendance/breaks', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getDashboard(
    String appKey,
    int employeeId, {
    String type = 'daily',
    String? month,
    String? fromDate,
    String? toDate,
  }) async {
    final body = {
      'app_key': appKey,
      'employee_id': employeeId,
      'type': type,
    };
    
    if (type == 'monthly' && month != null) body['month'] = month;
    if (type == 'range') {
      if (fromDate != null) body['from_date'] = fromDate;
      if (toDate != null) body['to_date'] = toDate;
    }
    
    return await _post('/api/attendance/dashboard', body);
  }
  
  static Future<Map<String, dynamic>> getPayrollSalary(String appKey, int employeeId, {String? month}) async {
    final body = {'app_key': appKey, 'employee_id': employeeId};
    if (month != null) body['month'] = month;
    return await _post('/api/payroll/salary', body);
  }
  
  static Future<Map<String, dynamic>> getLeaveAllocations(String appKey, int employeeId) async {
    return await _post('/api/leave/allocations', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getLeaveHistory(String appKey, int employeeId) async {
    return await _post('/api/leave/history', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> applyLeave({
    required String appKey,
    required int employeeId,
    required int leaveTypeId,
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    return await _post('/api/leave/apply', {
      'app_key': appKey,
      'employee_id': employeeId,
      'leave_type_id': leaveTypeId,
      'from_date': fromDate,
      'to_date': toDate,
      'reason': reason ?? '',
    });
  }
  
  static Future<Map<String, dynamic>> getLeaveStatus(String appKey, int leaveId) async {
    return await _post('/api/leave/status', {
      'app_key': appKey,
      'leave_id': leaveId,
    });
  }
  
  // ===============================
  // TIMESHEET & PROJECT APIs - FIXED
  // ===============================
  
  // FIX: Added employee_id parameter
  static Future<Map<String, dynamic>> getProjects(String appKey, int employeeId) async {
    return await _post('/api/custom/projects', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  // FIX: Added employee_id parameter
  static Future<Map<String, dynamic>> getTasks(String appKey, int employeeId, int projectId) async {
    return await _post('/api/custom/tasks', {
      'app_key': appKey,
      'employee_id': employeeId,
      'project_id': projectId,
    });
  }
  
  // FIX: Added employee_id parameter
  static Future<Map<String, dynamic>> getProjectsWithTasks(String appKey, int employeeId) async {
    return await _post('/api/custom/projects-with-tasks', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> startTimesheet(
    String appKey,
    int employeeId, {
    required int projectId,
    int? taskId,
  }) async {
    final body = {
      'app_key': appKey,
      'employee_id': employeeId,
      'project_id': projectId,
    };
    
    if (taskId != null) {
      body['task_id'] = taskId;
    }
    
    return await _post('/api/custom/timesheet/start', body);
  }
  
  // FIX: Changed timesheetId to lineId to match backend expectation
  static Future<Map<String, dynamic>> stopTimesheet(
    String appKey,
    int employeeId, {
    required int lineId,
  }) async {
    return await _post('/api/custom/timesheet/stop', {
      'app_key': appKey,
      'employee_id': employeeId,
      'line_id': lineId,  // FIX: Changed from timesheet_id to line_id
    });
  }
  
  static Future<Map<String, dynamic>> getTimesheetList(String appKey, int employeeId) async {
    return await _post('/api/custom/timesheet/list', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
  
  static Future<Map<String, dynamic>> getTimesheetSummary(String appKey, int employeeId) async {
    return await _post('/api/custom/timesheet/summary', {
      'app_key': appKey,
      'employee_id': employeeId,
    });
  }
}