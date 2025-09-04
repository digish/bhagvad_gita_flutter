import 'package:flutter/material.dart';

// Add a constructor that accepts the shlokaId
class ShlokaDetailScreen extends StatelessWidget {
  final String shlokaId;
  const ShlokaDetailScreen({super.key, required this.shlokaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shloka $shlokaId')),
      body: Center(
        child: Text('Shloka Detail Screen'),
      ),
    );
  }
}