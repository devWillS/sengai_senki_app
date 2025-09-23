import 'package:flutter/material.dart';

class InfoPortalScreen extends StatelessWidget {
  const InfoPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(title: const Text('情報ポータル')),
      body: const Center(child: Text('公式情報・お知らせは現在準備中です。')),
    );
  }
}
