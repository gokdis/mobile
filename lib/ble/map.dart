import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: EdgeInsets.all(80),
        minScale: 0.5,
        maxScale: 4,
        child: Image.asset(
          "assets/images/supermarket.png",
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
      ),
    );
  }
}
