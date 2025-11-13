// diarypage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Note class for sharing
class Note {
  final String title;
  final String body;
  final DateTime date;

  Note({
    required this.title,
    required this.body,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'date': date.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    date: DateTime.parse(map['date']),
  );
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  DiaryScreenState createState() => DiaryScreenState();
}

class DiaryScreenState extends State<DiaryScreen> {
  final Color backgroundColor = const Color(0xFF1A1D2E);

  final List<Note> _entries = [];
  int? _expandedIndex;

  String _userId = "guest";

  // 🔍 Search + Sort state
  String _searchQuery = '';
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("current_user") ?? "guest";
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('diary_entries_$_userId');

    if (stored != null) {
      final loaded = stored.map((s) => Note.fromMap(jsonDecode(s))).toList();
      if (mounted) {
        setState(() {
          _entries
            ..clear()
            ..addAll(loaded);
        });
      }
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
    _entries.map((e) => jsonEncode(e.toMap())).toList();

    await prefs.setStringList('diary_entries_$_userId', jsonList);
  }

  void addNote(Note note) {
    setState(() {
      _entries.add(note);
      _expandedIndex = null;
    });
    _saveNotes();
  }

  void addEntry(String body) {
    setState(() {
      _entries.add(Note(
        title: "Untitled",
        body: body,
        date: DateTime.now(),
      ));
      _expandedIndex = null;
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 FILTER entries
    List<Note> visibleEntries = _entries.where((note) {
      if (_searchQuery.isEmpty) return true;
      final text = (note.title + " " + note.body).toLowerCase();
      return text.contains(_searchQuery);
    }).toList();

    // 🔃 SORT entries
    visibleEntries.sort((a, b) {
      return _sortNewestFirst
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date);
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
                  hintText: 'Search',
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

          // Sort Row
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

          const SizedBox(height: 20),

          // List
          Expanded(
            child: visibleEntries.isEmpty
                ? const Center(
              child: Text(
                "No entries yet.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visibleEntries.length,
              itemBuilder: (context, index) {
                return _buildEntryCard(visibleEntries[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Note note, int index) {
    bool isExpanded = _entries.indexOf(note) == _expandedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            final realIndex = _entries.indexOf(note);
            _expandedIndex = isExpanded ? null : realIndex;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5C98D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title, date, menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(note.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      int realIndex = _entries.indexOf(note);

                      if (value == 'delete') {
                        setState(() {
                          _entries.removeAt(realIndex);
                          if (_expandedIndex == realIndex) {
                            _expandedIndex = null;
                          }
                        });
                        _saveNotes();
                      } else if (value == 'edit') {
                        final editedNote = await Navigator.push<Note>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditScreen(note: note),
                          ),
                        );

                        if (editedNote != null) {
                          setState(() {
                            _entries[realIndex] = editedNote;
                          });
                          _saveNotes();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),

              // Body / expanded content
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
                    note.body,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                crossFadeState: isExpanded
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
    return "${date.month}/${date.day}/${date.year}";
  }
}

// --- Edit screen unchanged ---
class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.note?.title ?? '');
    _bodyController =
        TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final newNote = Note(
      title: title,
      body: body,
      date: widget.note?.date ?? DateTime.now(),
    );

    Navigator.pop(context, newNote);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        backgroundColor: const Color(0xFF1A1D2E),
        actions: [
          TextButton(
            onPressed: _saveNote,
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
                hintText: 'Enter title',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Write entry',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
