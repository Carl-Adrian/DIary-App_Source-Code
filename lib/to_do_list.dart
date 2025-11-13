// to_do_list.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Task model
class Task {
  final String title;
  final String description;
  final DateTime date;
  bool isDone;

  Task({
    required this.title,
    required this.description,
    required this.date,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'isDone': isDone,
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    date: DateTime.parse(map['date']),
    isDone: map['isDone'] ?? false,
  );
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  TodoScreenState createState() => TodoScreenState();
}

class TodoScreenState extends State<TodoScreen> {
  final Color backgroundColor = const Color(0xFF1A1D2E);
  final List<Task> _tasks = [];
  int? _expandedIndex;

  String _userId = "guest";

  // Search + Sort state
  String _searchQuery = "";
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("current_user") ?? "guest";
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('todo_tasks_$_userId');

    if (stored != null) {
      final loaded = stored.map((s) => Task.fromMap(jsonDecode(s))).toList();
      if (mounted) {
        setState(() {
          _tasks
            ..clear()
            ..addAll(loaded);
        });
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList =
    _tasks.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('todo_tasks_$_userId', jsonList);
  }

  void addTask(Task task) {
    setState(() {
      _tasks.add(task);
      _expandedIndex = null;
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    // FILTER
    List<Task> visibleTasks = _tasks.where((task) {
      if (_searchQuery.isEmpty) return true;
      final text = (task.title + " " + task.description).toLowerCase();
      return text.contains(_searchQuery);
    }).toList();

    // SORT
    visibleTasks.sort((a, b) {
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
                  hintText: 'Search tasks',
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

          // Tasks list
          Expanded(
            child: visibleTasks.isEmpty
                ? const Center(
              child: Text(
                "No tasks yet.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: visibleTasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(visibleTasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    int index = _tasks.indexOf(task);
    bool isExpanded = index == _expandedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: task.isDone ? Colors.green[400] : const Color(0xFFF5C98D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(task.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Checkbox(
                    value: task.isDone,
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                    onChanged: (val) {
                      setState(() {
                        task.isDone = val ?? false;
                      });
                      _saveTasks();
                    },
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        setState(() {
                          _tasks.remove(task);
                          if (_expandedIndex == index) {
                            _expandedIndex = null;
                          }
                        });
                        _saveTasks();
                      } else if (value == 'edit') {
                        final editedTask = await Navigator.push<Task>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskEditScreen(
                              task: task,
                            ),
                          ),
                        );

                        if (editedTask != null) {
                          setState(() {
                            int realIndex = _tasks.indexOf(task);
                            _tasks[realIndex] = editedTask;
                          });
                          _saveTasks();
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

              // Expanded Description
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
                    task.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

// EDIT SCREEN
class TaskEditScreen extends StatefulWidget {
  final Task? task;
  final int? taskIndex;

  const TaskEditScreen({Key? key, this.task, this.taskIndex}) : super(key: key);

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final newTask = Task(
      title: title,
      description: description,
      date: widget.task?.date ?? DateTime.now(),
      isDone: widget.task?.isDone ?? false,
    );

    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        backgroundColor: const Color(0xFF1A1D2E),
        actions: [
          TextButton(
            onPressed: _saveTask,
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
                hintText: 'Enter task title',
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
                hintText: 'Enter task details',
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
