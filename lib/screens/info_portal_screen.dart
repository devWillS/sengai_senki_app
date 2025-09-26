import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoPortalScreen extends StatelessWidget {
  const InfoPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          '情報ポータル',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: const Center(
        child: Text(
          '公式情報・お知らせは現在準備中です。',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
