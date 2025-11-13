import 'package:flutter/material.dart';
import 'package:my_diary/register_page.dart';
import 'package:my_diary/reset_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  static const String id = 'LoginPage';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color backgroundColor = Color(0xFF1A1D2E);
  static const Color gradientStart = Color(0xFFA89CC8);
  static const Color gradientEnd = Color(0xFFD98481);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _profileImagePath;

  @override
  void initState() {
    super.initState();

    // Load last logged-in user avatar
    _loadLastLoggedInUser();

    // Live-update avatar when typing username
    _usernameController.addListener(() {
      _loadUserProfileFor(_usernameController.text.trim());
    });
  }

  /// Load avatar of the last logged-in user
  Future<void> _loadLastLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUser = prefs.getString("current_user");

    if (lastUser != null && lastUser.isNotEmpty) {
      final imagePath = prefs.getString("profile_picture_$lastUser");

      setState(() {
        _profileImagePath =
        (imagePath != null && File(imagePath).existsSync())
            ? imagePath
            : null;

        _usernameController.text = lastUser;

      });
    }
  }


  Future<void> _loadUserProfileFor(String username) async {
    if (username.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString("profile_picture_$username");

    setState(() {
      _profileImagePath =
      (imagePath != null && File(imagePath).existsSync())
          ? imagePath
          : null;
    });
  }

  Future<void> _login(BuildContext context) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password cannot be empty')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString("password_$username");

    if (storedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not found. Please register first.")),
      );
      return;
    }

    if (storedPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect password")),
      );
      return;
    }

    // SUCCESS — save current logged user
    await prefs.setString("current_user", username);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Circles
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradientEnd.withOpacity(0.3),
              ),
            ),
          ),

          Positioned(
            top: 80,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradientStart.withOpacity(0.3),
              ),
            ),
          ),

          Positioned(
            top: 160,
            left: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xfff2f2f2),
                    Color(0xff0092f2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            top: 245,
            right: 230,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xfff2f2f2),
                    Color(0xff0092f2),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar
                    CircleAvatar(
                      radius: 100,
                      backgroundImage: _profileImagePath != null
                          ? FileImage(File(_profileImagePath!))
                          : const AssetImage('assets/login_icon.jpg')
                      as ImageProvider,
                      backgroundColor: Colors.transparent,
                    ),

                    // Username field
                    Container(
                      margin: const EdgeInsets.only(top: 40, bottom: 30),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFECA1A6), Color(0xFFDB7093)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Username',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                        ),
                      ),
                    ),

                    // Password
                    Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFECA1A6), Color(0xFFDB7093)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                          _buildButton("Login", () => _login(context)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildButton("Register", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegisterPage()),
                            ).then((_) {
                              // Reload suggestions after registering
                              _loadLastLoggedInUser();
                            });
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResetPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: gradientEnd,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
