import 'package:flutter/material.dart';

class ShoppingListWidget extends StatefulWidget {
  @override
  ShoppingListWidgetState createState() => ShoppingListWidgetState();
}

class ShoppingListWidgetState extends State<ShoppingListWidget> {
  TextEditingController _itemController = TextEditingController();
  List<String> _items = [];

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
      ),
      body: Column(
        children: [
          _buildAddItemField(),
          _buildItemList(),
        ],
      ),
    );
  }

  Widget _buildAddItemField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              decoration: InputDecoration(
                hintText: 'Enter item',
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              _addItem();
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    String newItem = _itemController.text.trim();
    if (newItem.isNotEmpty) {
      setState(() {
        _items.add(newItem);
        _itemController.clear();
      });
    }
  }

  Widget _buildItemList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_items[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _removeItem(index);
              },
            ),
          );
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }
}
