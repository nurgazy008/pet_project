import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/Screenshot 2025-05-21 at 15.55.36.png",
          width: 800,
          height: 1200,
        ),
      ),
    );
  }
}
