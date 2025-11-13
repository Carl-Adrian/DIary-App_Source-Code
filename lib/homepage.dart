import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_diary/profile_page.dart';
import 'package:my_diary/to_do_list.dart';
import 'package:my_diary/weather_screen.dart';
import 'diarypage.dart';
import 'time_capsule_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color backgroundColor = const Color(0xFF1A1D2E);

  final GlobalKey<DiaryScreenState> diaryScreenKey = GlobalKey<DiaryScreenState>();
  final GlobalKey<TodoScreenState> todoScreenKey = GlobalKey<TodoScreenState>();
  final GlobalKey<WeatherPageState> weatherScreenKey = GlobalKey<WeatherPageState>();
  final GlobalKey<MemoryCapsuleScreenState> memoryScreenKey = GlobalKey<MemoryCapsuleScreenState>();

  int selectIndex = 0;
  File? _profileImage;

  String _currentUser = "guest";

  final List<String> pageTitles = ["DIARY", "TO DO", "WEATHER", "MEMORIES"];

  // shared weather state
  String _currentWeatherIcon = "☁️";
  int _currentWeatherTemp = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load current logged-in user
    _currentUser = prefs.getString("current_user") ?? "guest";

    // Load user-specific profile picture
    final imagePath = prefs.getString("profile_picture_$_currentUser");

    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    } else {
      setState(() {
        _profileImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DiaryScreen(key: diaryScreenKey),
      TodoScreen(key: todoScreenKey),
      WeatherPage(
        key: weatherScreenKey,
        onWeatherUpdate: (icon, temp) {
          setState(() {
            _currentWeatherIcon = icon;
            _currentWeatherTemp = temp;
          });
        },
      ),
      MemoryCapsuleScreen(key: memoryScreenKey),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // APP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA89CC8), Color(0xFFD98481)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  // PROFILE AVATAR
                  GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );

                      if (updated == true) {
                        _loadProfileImage(); // refresh AppBar
                      }
                    },
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : const AssetImage('assets/login_icon.jpg')
                      as ImageProvider,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AutoSizeText(
                        pageTitles[selectIndex],
                        maxLines: 1,
                        minFontSize: 18,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // WEATHER
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currentWeatherIcon,
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "$_currentWeatherTemp°",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Page Body
            Expanded(child: pages[selectIndex]),
          ],
        ),
      ),

      // FAB
      floatingActionButton: RawMaterialButton(
        onPressed: () async {
          if (selectIndex == 0) {
            final newNote = await Navigator.push<Note>(
              context,
              MaterialPageRoute(builder: (_) => const NoteEditScreen()),
            );
            if (newNote != null) diaryScreenKey.currentState?.addNote(newNote);
          } else if (selectIndex == 1) {
            final newTask = await Navigator.push<Task>(
              context,
              MaterialPageRoute(builder: (_) => const TaskEditScreen()),
            );
            if (newTask != null) todoScreenKey.currentState?.addTask(newTask);
          } else if (selectIndex == 3) {
            final newMemory = await Navigator.push<Memory>(
              context,
              MaterialPageRoute(builder: (_) => const MemoryEditScreen()),
            );
            if (newMemory != null) memoryScreenKey.currentState?.addMemory(newMemory);
          }
        },
        elevation: 6.0,
        fillColor: const Color.fromRGBO(64, 74, 134, 1.0),
        shape: const CircleBorder(),
        constraints: const BoxConstraints.tightFor(width: 70.0, height: 70.0),
        child: const Icon(Icons.add, size: 25),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromRGBO(149, 120, 227, 1.0),
        shape: const CircularNotchedRectangle(),
        notchMargin: 9.0,
        child: Row(
          children: [
            Expanded(child: _buildNavItem(Icons.note, "Diary", 0)),
            Expanded(child: _buildNavItem(Icons.list, "ToDo", 1)),
            const SizedBox(width: 70),
            Expanded(child: _buildNavItem(Icons.cloud, "Weather", 2)),
            Expanded(child: _buildNavItem(Icons.photo_album, "Memories", 3)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return MaterialButton(
      onPressed: () {
        setState(() {
          selectIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
