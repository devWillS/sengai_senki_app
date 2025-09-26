import 'package:flutter/material.dart';
import 'package:senkai_sengi/widgets/diamond_tag.dart';

class CardName extends StatelessWidget {
  const CardName({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final double fontSize = 25;
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900);
    if (name.startsWith("《") && name.endsWith("》")) {
      // 《》で囲まれた文字列から《》を除去して中身を取得
      final text = name.substring(1, name.length - 1);
      return DiamondTag(
        text: text,
        centerColor: Colors.transparent,
        textStyle: style,
        height: fontSize * 1.5,
      );
    }
    return Text(name, style: style);
  }
}
