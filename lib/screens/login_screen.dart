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
          error = "Employee not registered!";
        });
      }
    } else {
      if (usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty) {
        error = "Incorrect password!";
      } else {
        error = "Please enter username and password!";
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 60, color: Colors.blue.shade700),
                    SizedBox(height: 10),
                    Text(
                      "Employee Login",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        labelText: "Username",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue.shade700,
                        ),
                        onPressed: isLoading ? null : _login,
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Login",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
