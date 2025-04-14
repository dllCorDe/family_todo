import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'task.dart';
import 'shopping_list.dart';
import 'auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const ToDoHomePage();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class ToDoHomePage extends StatefulWidget {
  const ToDoHomePage({super.key});

  @override
  State<ToDoHomePage> createState() => _ToDoHomePageState();
}

class _ToDoHomePageState extends State<ToDoHomePage> {
  final List<String> _familyMembers = ['Mom', 'Dad', 'Alex', 'Sam'];
  final TextEditingController _taskController = TextEditingController();
  String? _selectedMember;
  String? _familyId;
  String? _errorMessage; // Add this to track errors
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupUserAndFamily();
  }

  Future<void> _setupUserAndFamily() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated. Please sign in again.';
        });
        return;
      }

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // New user: Create a new family and add the user to it
        final familyRef = await _firestore.collection('families').add({
          'createdBy': user.uid,
          'members': [user.uid],
        });
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'familyId': familyRef.id,
        });
        if (mounted) { // Check if the widget is still mounted
          setState(() {
            _familyId = familyRef.id;
          });
        }
      } else {
        if (mounted) { // Check if the widget is still mounted
          setState(() {
            _familyId = userDoc.data()!['familyId'];
          });
        }
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted
        setState(() {
          _errorMessage = 'Error setting up user: $e';
        });
      }
    }
  }

  void _addTask() async {
        _selectedMember = null;
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
                onPressed: () => Navigator.pop(context),
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

    if (result != null && _familyId != null) {
      try {
        await _firestore.collection('families').doc(_familyId).collection('tasks').add({
          'name': result['taskName'],
          'isCompleted': false,
          'assignedMember': result['assignedMember'],
        });
        _taskController.clear();
        _selectedMember = null;
      } catch (e) {
        if (mounted) { // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add task: $e')),
          );
        }
      }
    } else {
      if (mounted) { // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family ID not set. Please try signing out and back in.')),
        );
      }
    }
  }

  void _toggleTaskCompletion(String taskId, bool currentValue) {
    if (_familyId != null) {
      _firestore
          .collection('families')
          .doc(_familyId)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': !currentValue});
    }
  }

  void _deleteTask(String taskId, String taskName) {
    if (_familyId != null) {
      _firestore
          .collection('families')
          .doc(_familyId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "$taskName" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family To-Do List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingListScreen(familyId: _familyId)),
              );
            },
            tooltip: 'Go to Shopping List',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _familyId == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('families')
                      .doc(_familyId)
                      .collection('tasks')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Let’s start adding tasks!'));
                    }
                    final tasks = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final taskData = tasks[index].data() as Map<String, dynamic>;
                        final task = Task(
                          name: taskData['name'],
                          isCompleted: taskData['isCompleted'],
                          assignedMember: taskData['assignedMember'],
                        );
                        return Dismissible(
                          key: Key(tasks[index].id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteTask(tasks[index].id, task.name);
                          },
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) {
                                _toggleTaskCompletion(tasks[index].id, task.isCompleted);
                              },
                            ),
                            title: Text(
                              task.name,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            subtitle: task.assignedMember != null
                                ? Text('Assigned to: ${task.assignedMember}')
                                : null,
                          ),
                        );
                      },
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