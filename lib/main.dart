import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final String apiUrl = "http://10.0.2.2/todo_app"; // Make sure this is the correct IP for real device
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // Fetch tasks from the backend
  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/get_tasks.php'));
      if (response.statusCode == 200) {
        final List tasks = jsonDecode(response.body);
        setState(() {
          _tasks.clear();
          _tasks.addAll(tasks.map((e) => Map<String, dynamic>.from(e)));
        });
      } else {
        print('Error fetching tasks: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  // Add a new task
  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl/add_task.php'),
          body: {'name': _taskController.text},
        );
        if (response.statusCode == 200) {
          _taskController.clear();
          _fetchTasks();
        } else {
          print('Failed to add task: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error adding task: $e');
      }
    }
  }

  // Toggle completion status
  Future<void> _toggleCompletion(int id, bool isCompleted) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/update_task.php'),
        body: {'id': '$id', 'is_completed': isCompleted ? '1' : '0'},
      );
      if (response.statusCode == 200) {
        _fetchTasks();
      } else {
        print('Failed to update task completion: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  // Remove task
  Future<void> _removeTask(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/delete_task.php'),
        body: {'id': '$id'},
      );
      if (response.statusCode == 200) {
        _fetchTasks();
      } else {
        print('Failed to delete task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Field for New Task
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: 'Enter a task',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.blue, size: 30),
                    onPressed: _addTask,
                  ),
                ],
              ),
            ),
            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: task['is_completed'] == 1,
                        onChanged: (bool? value) {
                          if (value != null) {
                            _toggleCompletion(task['id'], value);
                          }
                        },
                      ),
                      title: Text(
                        task['name'],
                        style: TextStyle(
                          fontSize: 18,
                          decoration: task['is_completed'] == 1
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeTask(task['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
