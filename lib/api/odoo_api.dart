import 'dart:convert';
import 'package:http/http.dart' as http;

class OdooService {
  final String baseUrl = "https://it-company.odoo.com"; // Odoo URL
  final String db = "it-company"; // Odoo database name

  Future<Map<String, dynamic>?> login(String username, String password) async {
    var url = Uri.parse('$baseUrl/jsonrpc');

    var body = {
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "common",
        "method": "authenticate",
        "args": [db, username, password, {}]
      },
      "id": 1
    };

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    var data = jsonDecode(response.body);

    if (data["result"] != false) {
      return {
        "uid": data["result"],
        "username": username,
        "password": password
      };
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEmployeeData(
      int uid, String password) async {
    var url = Uri.parse('$baseUrl/jsonrpc');

    var body = {
      "jsonrpc": "2.0",
      "method": "call",
      "params": {
        "service": "object",
        "method": "execute_kw",
        "args": [
          db,
          uid,
          password,
          "hr.employee",
          "search_read",
          [
            [["user_id", "=", uid]]
          ],
          {
            "fields": ["name", "work_email", "job_title", "work_phone"],
            "limit": 1
          }
        ]
      },
      "id": 2
    };

    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));

    var data = jsonDecode(response.body);

    if (data["result"].isNotEmpty) {
      return data["result"][0];
    }
    return null;
  }
}
