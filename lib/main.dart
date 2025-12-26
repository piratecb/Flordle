import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const wordle());
}

class wordle extends StatefulWidget {
  const wordle({super.key});

  @override
  State<wordle> createState() => _wordleState();
}

class _wordleState extends State<wordle> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Wordle'),
        ),
      ),
    );
  }
}
