import 'package:bordered_text/bordered_text.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/card_detail_const.dart';
import 'package:senkai_sengi/widgets/triangle.dart';

class DiamondTag extends StatelessWidget {
  const DiamondTag({
    super.key,
    required this.text,
    this.centerColor,
    this.textStyle,
    this.height,
  });

  final String text;
  final Color? centerColor;
  final TextStyle? textStyle;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? CardDetailConst.lineHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotatedBox(
            quarterTurns: 2,
            child: CustomPaint(
              painter: Triangle(color: Colors.red),
              child: SizedBox(
                height: height ?? CardDetailConst.lineHeight,
                width: 3,
              ),
            ),
          ),
          Container(
            height: height ?? CardDetailConst.lineHeight,
            padding: EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(color: centerColor ?? Colors.yellow),
            child: Center(
              widthFactor: 1.0,
              child: BorderedText(
                strokeColor: textStyle != null
                    ? Colors.transparent
                    : Colors.black,
                strokeWidth: 2,
                child: Text(
                  text,
                  style:
                      textStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: CardDetailConst.fontSize,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: Triangle(color: Colors.red),
            child: SizedBox(
              height: height ?? CardDetailConst.lineHeight,
              width: 3,
            ),
          ),
        ],
      ),
    );
  }
}
