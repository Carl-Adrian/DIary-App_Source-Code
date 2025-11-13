// time_capsule_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Memory model
class Memory {
  final String title;
  final String description;
  final DateTime unlockDate;

  Memory({
    required this.title,
    required this.description,
    required this.unlockDate,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'unlockDate': unlockDate.toIso8601String(),
  };

  factory Memory.fromMap(Map<String, dynamic> map) => Memory(
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    unlockDate: DateTime.parse(map['unlockDate']),
  );
}

class MemoryCapsuleScreen extends StatefulWidget {
  const MemoryCapsuleScreen({Key? key}) : super(key: key);

  @override
  MemoryCapsuleScreenState createState() => MemoryCapsuleScreenState();
}

class MemoryCapsuleScreenState extends State<MemoryCapsuleScreen> {
  final Color backgroundColor = const Color(0xFF1A1D2E);
  final List<Memory> _memories = [];
  int? _expandedIndex;

  Timer? _unlockTimer;

  String _userId = "guest";
//search
  String _searchQuery = "";
//sort
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadUser();

    _unlockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("current_user") ?? "guest";

    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('memories_$_userId');

    if (stored != null) {
      final loaded = stored.map((s) => Memory.fromMap(jsonDecode(s))).toList();

      if (mounted) {
        setState(() {
          _memories
            ..clear()
            ..addAll(loaded);
        });
      }
    }
  }

  Future<void> _saveMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _memories.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('memories_$_userId', jsonList);
  }

  void addMemory(Memory memory) {
    setState(() {
      _memories.add(memory);
      _expandedIndex = null;
    });
    _saveMemories();
  }

  @override
  Widget build(BuildContext context) {
    // Search filter
    List<Memory> visibleMemories = _memories.where((memory) {
      if (_searchQuery.isEmpty) return true;
      final text =
      (memory.title + " " + memory.description).toLowerCase();
      return text.contains(_searchQuery);
    }).toList();

    // 🔃 QUERY: Sort by unlock date
    visibleMemories.sort((a, b) {
      return _sortNewestFirst
          ? b.unlockDate.compareTo(a.unlockDate)
          : a.unlockDate.compareTo(b.unlockDate);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: 'Search memories',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Sort Row (matches Diary & To-Do)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _sortNewestFirst = !_sortNewestFirst;
                });
              },
              child: Row(
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Icon(
                    _sortNewestFirst
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: visibleMemories.isEmpty
                ? const Center(
              child: Text(
                "No memories yet.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visibleMemories.length,
              itemBuilder: (context, index) {
                return _buildMemoryCard(visibleMemories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    int index = _memories.indexOf(memory);
    bool isExpanded = index == _expandedIndex;
    bool isUnlocked = DateTime.now().isAfter(memory.unlockDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (isUnlocked) {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "This memory will unlock on ${_formatDate(memory.unlockDate)}",
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFF9C88FF) : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Unlock Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Unlocks: ${_formatDate(memory.unlockDate)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'delete') {
                        setState(() {
                          _memories.remove(memory);
                          if (_expandedIndex == index) {
                            _expandedIndex = null;
                          }
                        });
                        _saveMemories();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),

              // Description when unlocked
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B8FA8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    memory.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                crossFadeState: (isExpanded && isUnlocked)
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

// MEMORY EDIT SCREEN (UNCHANGED)
class MemoryEditScreen extends StatefulWidget {
  final Memory? memory;

  const MemoryEditScreen({Key? key, this.memory}) : super(key: key);

  @override
  _MemoryEditScreenState createState() => _MemoryEditScreenState();
}

class _MemoryEditScreenState extends State<MemoryEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.memory?.description ?? '');
    _selectedDate = widget.memory?.unlockDate ??
        DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveMemory() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and unlock date')),
      );
      return;
    }

    final newMemory = Memory(
      title: title,
      description: description,
      unlockDate: _selectedDate!,
    );

    Navigator.pop(context, newMemory);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memory != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Memory' : 'New Memory'),
        backgroundColor: const Color(0xFF1A1D2E),
        actions: [
          TextButton(
            onPressed: _saveMemory,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      backgroundColor: const Color(0xFF1A1D2E),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter memory title',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Description',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter memory details',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.lock_clock),
              label: Text(
                _selectedDate == null
                    ? "Pick unlock date & time"
                    : "Unlocks on: ${_selectedDate.toString()}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
