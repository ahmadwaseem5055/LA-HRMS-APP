import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginApi {
  final String baseUrl = "https://lahoreanalytica-la1-uat-20891347.dev.odoo.com";

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
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (e) {
      print("❌ Login error: $e");
    }

    return null;
  }
}
