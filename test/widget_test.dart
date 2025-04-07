import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:family_todo/main.dart';

void main() {
  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

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
    expect(find.text('Mom'), findsWidgets);
    expect(find.text('Assign to'), findsNothing);
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
    await tester.drag(find.text('Buy groceries'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Task "Buy groceries" deleted'), findsOneWidget);

    // Verify that the task is removed and the placeholder text reappears.
    expect(find.text('Buy groceries'), findsNothing);
    expect(find.text('Let’s start adding tasks!'), findsOneWidget);
  });

  testWidgets('Shopping list allows adding and deleting items', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FamilyToDoApp());

    // Navigate to the shopping list screen.
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();

    // Verify that the shopping list title is displayed.
    expect(find.text('Shopping List'), findsOneWidget);

    // Verify that the placeholder text is displayed initially.
    expect(find.text('Let’s start adding items!'), findsOneWidget);

    // Add an item.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify that the item is added.
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Let’s start adding items!'), findsNothing);

    // Delete the item.
    await tester.drag(find.text('Milk'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Item "Milk" deleted'), findsOneWidget);

    // Verify that the item is removed and the placeholder text reappears.
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Let’s start adding items!'), findsOneWidget);
  });
}