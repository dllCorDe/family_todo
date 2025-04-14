import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListScreen extends StatefulWidget {
  final String? familyId;

  const ShoppingListScreen({super.key, this.familyId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

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
            onPressed: () => Navigator.pop(context),
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

    if (newItem != null && newItem.isNotEmpty && widget.familyId != null) {
      await _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('shopping_items')
          .add({'name': newItem});
      _itemController.clear();
    }
  }

  void _deleteItem(String itemId, String itemName) {
    if (widget.familyId != null) {
      _firestore
          .collection('families')
          .doc(widget.familyId)
          .collection('shopping_items')
          .doc(itemId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item "$itemName" deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
      body: widget.familyId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('families')
                  .doc(widget.familyId)
                  .collection('shopping_items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Let’s start adding items!'));
                }
                final items = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData = items[index].data() as Map<String, dynamic>;
                    final itemName = itemData['name'] as String;
                    return Dismissible(
                      key: Key(items[index].id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteItem(items[index].id, itemName);
                      },
                      child: ListTile(
                        title: Text(itemName),
                      ),
                    );
                  },
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