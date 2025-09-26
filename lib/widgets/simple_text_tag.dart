import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/card_detail_const.dart';

class SimpleTextTag extends StatelessWidget {
  const SimpleTextTag({
    super.key,
    required this.text,
    required this.color,
    this.widthFactor = 1.3,
  });
  final String text;
  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CardDetailConst.lineHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        widthFactor: widthFactor,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: CardDetailConst.fontSize,
          ),
        ),
      ),
    );
  }
}
