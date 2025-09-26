import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          'イベント一覧',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: const Center(
        child: Text('イベント情報は現在準備中です。', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
