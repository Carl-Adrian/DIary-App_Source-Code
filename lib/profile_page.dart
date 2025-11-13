import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nicknameController = TextEditingController();

  late SharedPreferences _prefs;
  String _userId = "guest";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _prefs = await SharedPreferences.getInstance();

    // Current logged-in user
    _userId = _prefs.getString("current_user") ?? "guest";

    // Load nickname for this user
    _nicknameController.text =
        _prefs.getString("nickname_$_userId") ?? '';

    // Load profile picture for this user
    final imagePath = _prefs.getString("profile_picture_$_userId");
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _image = File(imagePath);
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    await _prefs.setString("nickname_$_userId", _nicknameController.text);

    if (_image != null) {
      await _prefs.setString("profile_picture_$_userId", _image!.path);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );

    Navigator.pop(context, true); // 👈 tell HomePage to refresh
  }

  Future<void> _logout() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true), // refresh on back
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : const AssetImage('assets/login_icon.jpg')
                  as ImageProvider,
                ),
              ),

              const SizedBox(height: 20),

              // Nickname Input
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),

              const SizedBox(height: 10),

              // Logout Button
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Logout'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _logout();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
