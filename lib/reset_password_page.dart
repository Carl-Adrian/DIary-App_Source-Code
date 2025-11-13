import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  static const String id = 'ResetPassword';
  final Color backgroundColor = Color(0xFF1A1D2E);
  final Color gradientStart = Color(0xFFA89CC8);
  final Color gradientEnd = Color(0xFFD98481);

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
                Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Please enter the email address that you have used creating the account.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                _buildInput("Email"),
                SizedBox(height: 30),
                _buildButton("Submit", context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint) {
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
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context); // for now, just pop back to login
      },
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
