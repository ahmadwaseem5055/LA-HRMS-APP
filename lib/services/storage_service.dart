import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static const String _appKeyKey = 'app_key';
  static const String _employeeIdKey = 'employee_id';
  static const String _employeeNameKey = 'employee_name';
  static const String _employeeEmailKey = 'employee_email';
  static const String _employeeDeptKey = 'employee_dept';
  static const String _employeeImageKey = 'employee_image';
  static const String _employeeCompanyKey = 'employee_company';
  static const String _employeeJobKey = 'employee_job';
  static const String _employeeCodeKey = 'employee_code'; // Added
  static const String _isLoggedInKey = 'is_logged_in';
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }
  
  static Future<void> saveAppKey(String appKey) async {
    await _instance.setString(_appKeyKey, appKey);
  }
  
  static Future<String?> getAppKey() async {
    return _instance.getString(_appKeyKey);
  }
  
  static Future<void> saveEmployeeData(Map<String, dynamic> data) async {
    await _instance.setInt(_employeeIdKey, data['employee_id']);
    await _instance.setString(_employeeNameKey, data['employee_name'] ?? '');
    await _instance.setString(_employeeEmailKey, data['email'] ?? '');
    await _instance.setString(_employeeDeptKey, data['department'] ?? '');
    await _instance.setString(_employeeImageKey, data['image'] ?? '');
    await _instance.setString(_employeeCompanyKey, data['company'] ?? '');
    await _instance.setString(_employeeJobKey, data['job_position'] ?? '');
    
    // Generate employee code from ID if not provided
    String employeeCode = data['employee_code'] ?? 
                         data['code'] ?? 
                         'EMP-${data['employee_id']?.toString().padLeft(4, '0') ?? '0000'}';
    await _instance.setString(_employeeCodeKey, employeeCode);
    
    await _instance.setBool(_isLoggedInKey, true);
  }
  
  static Future<int?> getEmployeeId() async {
    return _instance.getInt(_employeeIdKey);
  }
  
  static Future<String?> getEmployeeName() async {
    return _instance.getString(_employeeNameKey);
  }
  
  static Future<String?> getEmployeeEmail() async {
    return _instance.getString(_employeeEmailKey);
  }
  
  static Future<String?> getDepartment() async {
    return _instance.getString(_employeeDeptKey);
  }
  
  static Future<String?> getEmployeeImage() async {
    return _instance.getString(_employeeImageKey);
  }
  
  static Future<String?> getCompany() async {
    return _instance.getString(_employeeCompanyKey);
  }
  
  static Future<String?> getJobPosition() async {
    return _instance.getString(_employeeJobKey);
  }
  
  // Added method for employee code
  static Future<String?> getEmployeeCode() async {
    return _instance.getString(_employeeCodeKey);
  }
  
  // Method to manually set employee code if needed
  static Future<void> setEmployeeCode(String code) async {
    await _instance.setString(_employeeCodeKey, code);
  }
  
  static Future<bool> isLoggedIn() async {
    return _instance.getBool(_isLoggedInKey) ?? false;
  }
  
  static Future<void> logout() async {
    await _instance.remove(_employeeIdKey);
    await _instance.remove(_employeeNameKey);
    await _instance.remove(_employeeEmailKey);
    await _instance.remove(_employeeDeptKey);
    await _instance.remove(_employeeImageKey);
    await _instance.remove(_employeeCompanyKey);
    await _instance.remove(_employeeJobKey);
    await _instance.remove(_employeeCodeKey);
    await _instance.setBool(_isLoggedInKey, false);
  }
  
  static Future<void> clearAll() async {
    await _instance.clear();
  }
}