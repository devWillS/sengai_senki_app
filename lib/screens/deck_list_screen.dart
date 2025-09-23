import 'package:flutter/material.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(title: const Text('デッキ一覧')),
      body: const Center(child: Text('デッキ一覧は現在準備中です。')),
    );
  }
}
