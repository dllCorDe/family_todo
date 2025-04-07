import 'dart:convert';

class Task {
  String name;
  bool isCompleted;
  String? assignedMember;

  Task({
    required this.name,
    this.isCompleted = false,
    this.assignedMember,
  });

  // Convert a Task to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'assignedMember': assignedMember,
    };
  }

  // Create a Task from a Map (for deserialization)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'] as String,
      isCompleted: map['isCompleted'] as bool,
      assignedMember: map['assignedMember'] as String?,
    );
  }

  // Convert Task to JSON string
  String toJson() => jsonEncode(toMap());

  // Create Task from JSON string
  factory Task.fromJson(String source) => Task.fromMap(jsonDecode(source));
}