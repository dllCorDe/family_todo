import 'package:flutter/material.dart';
import 'task.dart';

void main() {
  runApp(const FamilyToDoApp());
}

class FamilyToDoApp extends StatelessWidget {
  const FamilyToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family To-Do',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue[50],
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const ToDoHomePage(),
    );
  }
}

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({super.key});

  @override
  State<ToDoHomePage> createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  // List to store tasks
  final List<Task> _tasks = [];

  // List of family members (you can customize this list)
  final List<String> _familyMembers = ['Mom', 'Dad', 'Alex', 'Sam'];

  // Controller for the text field in the dialog
  final TextEditingController _taskController = TextEditingController();

  // Variable to store the selected family member in the dialog
  String? _selectedMember;

  // Method to show a dialog for adding a new task
    // Method to show a dialog for adding a new task
  void _addTask() async {
    _selectedMember = null; // Reset the selected member for each new task
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            title: const Text('Add a New Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(hintText: 'Enter task name'),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  hint: const Text('Assign to'),
                  value: _selectedMember,
                  isExpanded: true,
                  items: _familyMembers.map((String member) {
                    return DropdownMenuItem<String>(
                      value: member,
                      child: Text(member),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    dialogSetState(() {
                      _selectedMember = newValue;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancel button
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_taskController.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'taskName': _taskController.text,
                      'assignedMember': _selectedMember,
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    // If a new task was added, update the list and clear the controller
    if (result != null) {
      setState(() {
        _tasks.add(Task(
          name: result['taskName'],
          assignedMember: result['assignedMember'],
        ));
      });
      _taskController.clear();
      _selectedMember = null;
    }
  }

  // Method to toggle task completion
  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
    });
  }

  // Method to delete a task
  void _deleteTask(int index) {
    final String taskName = _tasks[index].name;
    setState(() {
      _tasks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task "$taskName" deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family To-Do List'),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('Let’s start adding tasks!'))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(_tasks[index].name),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteTask(index);
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: _tasks[index].isCompleted,
                      onChanged: (value) {
                        _toggleTaskCompletion(index);
                      },
                    ),
                    title: Text(
                      _tasks[index].name,
                      style: TextStyle(
                        decoration: _tasks[index].isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: _tasks[index].assignedMember != null
                        ? Text('Assigned to: ${_tasks[index].assignedMember}')
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}