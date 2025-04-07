class Task {
  String name;
  bool isCompleted;
  String? assignedMember; // Nullable string to store the family member's name

  Task({
    required this.name,
    this.isCompleted = false,
    this.assignedMember,
  });
}