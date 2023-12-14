import 'package:flutter/material.dart';
import 'package:gokdis/ble/map.dart';

class ShoppingListWidget extends StatefulWidget {
  @override
  ShoppingListWidgetState createState() => ShoppingListWidgetState();
}

class ShoppingListWidgetState extends State<ShoppingListWidget> {
  TextEditingController _itemController = TextEditingController();
  List<String> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        backgroundColor: Color(0xFFFFA500),
      ),
      body: Column(
        children: [
          _buildAddItemField(),
          _buildItemList(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              navigateToMap();
            },
            child: Icon(Icons.map),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            child: Icon(Icons.campaign),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(16),
              backgroundColor: Colors.orange,
            ),
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
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

  void navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(),
      ),
    );
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
