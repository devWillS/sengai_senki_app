import 'package:flutter/material.dart';

import 'screens/card_list_screen.dart';

void main() {
  runApp(const SenkaiSengiApp());
}

class SenkaiSengiApp extends StatelessWidget {
  const SenkaiSengiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Senkai Sengi Cards',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB33333)),
        useMaterial3: true,
      ),
      home: const CardListScreen(),
    );
  }
}
