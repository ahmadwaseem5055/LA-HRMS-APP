import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginApi {
  final String baseUrl = "https://lahoreanalytica-la1.odoo.com";

  Future<Map<String, dynamic>?> login(String username, String password) async {
    username = username.trim();
    password = password.trim();

    // Create the URL (query params like Postman example)
    final url = Uri.parse(
      "$baseUrl/api/login?username=$username&password=$password",
    );

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
        print("🔹 Parsed data: $data");
        
        if (data['success'] == true) {
          // Handle the mobile field - convert boolean false to "N/A"
          if (data['mobile'] == false) {
            data['mobile'] = 'N/A';
          }
          
          // Ensure all fields are strings for display
          data['employee_id'] = data['employee_id']?.toString() ?? 'N/A';
          data['employee_name'] = data['employee_name']?.toString() ?? 'N/A';
          data['email'] = data['email']?.toString() ?? 'N/A';
          data['department'] = data['department']?.toString() ?? 'N/A';
          data['company'] = data['company']?.toString() ?? 'N/A';
          
          print("🔹 Processed user data: $data");
          return data;
        } else {
          print("❌ Login failed: success is false");
          return null;
        }
      } else {
        print("❌ HTTP Error: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Login error: $e");
      return null;
    }
  }
}