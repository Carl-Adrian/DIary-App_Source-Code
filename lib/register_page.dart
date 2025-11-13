import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  static const String id = 'RegisterPage';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Color backgroundColor = Color(0xFF1A1D2E);
  final Color gradientStart = Color(0xFFA89CC8);
  final Color gradientEnd = Color(0xFFD98481);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Reject if user already exists
    if (prefs.containsKey("password_$username")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "$username" already exists.')),
      );
      return;
    }

    // Save user info using unique keys
    await prefs.setString("username_$username", username);
    await prefs.setString("email_$username", email);
    await prefs.setString("password_$username", password);

    // Default nickname is username
    await prefs.setString("nickname_$username", username);

    // Empty default profile picture (user can change later)
    await prefs.remove("profile_picture_$username");

    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful! Please log in.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Registration",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                _buildInput("Username", _usernameController, false),
                SizedBox(height: 20),
                _buildInput("Email", _emailController, false),
                SizedBox(height: 20),
                _buildInput("Password", _passwordController, true),
                SizedBox(height: 40),
                _buildButton("Register"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String hint, TextEditingController controller, bool obscureText) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: gradientEnd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
