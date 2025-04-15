import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Define the ShoppingItem class
class ShoppingItem {
  final String name;

  ShoppingItem({required this.name});
}

class ShoppingListScreen extends StatefulWidget {
  final String familyId;

  const ShoppingListScreen({super.key, required this.familyId});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _itemController = TextEditingController();

  void _addItem() async {
    if (_itemController.text.isNotEmpty) {
      await _firestore.collection('families').doc(widget.familyId).collection('shopping_items').add({
        'name': _itemController.text,
      });
      _itemController.clear();
    }
  }

  void _deleteItem(String itemId, String itemName) {
    _firestore.collection('families').doc(widget.familyId).collection('shopping_items').doc(itemId).delete();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(hintText: 'Add a new item'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('No items yet! Let’s add some.'));
                }
                final items = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData = items[index].data() as Map<String, dynamic>;
                    final item = ShoppingItem(name: itemData['name']);
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
                        _deleteItem(items[index].id, item.name);
                      },
                      child: ListTile(
                        title: Text(item.name),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }
}