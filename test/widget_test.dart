import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_todo/main.dart';

void main() {
  testWidgets('To-Do app allows adding, completing, deleting, and assigning tasks', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FamilyToDoApp());

    // Verify that the app title is displayed.
    expect(find.text('Family To-Do List'), findsOneWidget);

    // Verify that the placeholder text is displayed initially.
    expect(find.text('Let’s start adding tasks!'), findsOneWidget);

    // Add a task with an assigned family member.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Buy groceries');
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mom').last);
    await tester.pumpAndSettle();
    // Verify that the dropdown now shows "Mom".
    expect(find.text('Mom'), findsWidgets); // Should find "Mom" in the dropdown
    expect(find.text('Assign to'), findsNothing); // "Assign to" should no longer be visible
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify that the task is added with the assigned member.
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Assigned to: Mom'), findsOneWidget);
    expect(find.text('Let’s start adding tasks!'), findsNothing);

    // Mark the task as completed.
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == 'Buy groceries' &&
        widget.style?.decoration == TextDecoration.lineThrough), findsOneWidget);

    // Delete the task.
    await tester.drag(find.text('Buy groceries'), const Offset(-500, 0)); // Swipe left
    await tester.pumpAndSettle(); // Wait for the SnackBar to appear
    expect(find.text('Task "Buy groceries" deleted'), findsOneWidget);

    // Verify that the task is removed and the placeholder text reappears.
    expect(find.text('Buy groceries'), findsNothing);
    expect(find.text('Let’s start adding tasks!'), findsOneWidget);
  });
}