import 'package:flutter/material.dart';
import '../api/odoo_api.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final odoo = OdooService();
  bool isLoading = false;
  String? error;

  void _login() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    var loginData = await odoo.login(
      usernameController.text.trim(),
      passwordController.text.trim(),
    );

    if (loginData != null) {
      var employeeData = await odoo.getEmployeeData(
        loginData["uid"],
        loginData["password"],
      );

      if (employeeData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(employee: employeeData),
          ),
        );
      } else {
        setState(() {
          error = "Employee record not found!";
        });
      }
    } else {
      setState(() {
        error = "Invalid username or password!";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            if (error != null) ...[
              SizedBox(height: 8),
              Text(error!, style: TextStyle(color: Colors.red)),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              child:
                  isLoading ? CircularProgressIndicator() : Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
