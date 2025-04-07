import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // List to store shopping items
  final List<String> _shoppingItems = [];

  // Controller for the text field in the dialog
  final TextEditingController _itemController = TextEditingController();

  // Method to add a new shopping item
  void _addItem() async {
    final String? newItem = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a New Item'),
        content: TextField(
          controller: _itemController,
          decoration: const InputDecoration(hintText: 'Enter item name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel button
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_itemController.text.isNotEmpty) {
                Navigator.pop(context, _itemController.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newItem != null && newItem.isNotEmpty) {
      setState(() {
        _shoppingItems.add(newItem);
      });
      _itemController.clear();
    }
  }

  // Method to delete a shopping item
  void _deleteItem(int index) {
    final String itemName = _shoppingItems[index];
    setState(() {
      _shoppingItems.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item "$itemName" deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
      body: _shoppingItems.isEmpty
          ? const Center(child: Text('Let’s start adding items!'))
          : ListView.builder(
              itemCount: _shoppingItems.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(_shoppingItems[index]),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteItem(index);
                  },
                  child: ListTile(
                    title: Text(_shoppingItems[index]),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }
}