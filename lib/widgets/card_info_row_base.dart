import 'package:flutter/material.dart';
import 'package:senkai_sengi/utils/card_detail_const.dart';
import 'package:senkai_sengi/widgets/diamond_tag.dart';
import 'package:senkai_sengi/widgets/simple_text_tag.dart';

class CardInfoRowBase extends StatelessWidget {
  const CardInfoRowBase({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.black,
          fontSize: CardDetailConst.fontSize,
        ),
        children: parseTextToSpans(value),
      ),
    );
  }

  List<InlineSpan> parseTextToSpans(String input) {
    // 【】、《》、『』をキャプチャする正規表現
    final tagPattern = RegExp(r'(?:【[^】]+】|《[^》]+》|『[^』]+』)');
    final matches = tagPattern.allMatches(input);

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        final normalText = input.substring(lastIndex, match.start);
        spans.addAll(parseBoldSegments(normalText));
      }

      final keyword = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: buildTag(keyword),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < input.length) {
      spans.addAll(parseBoldSegments(input.substring(lastIndex)));
    }

    return spans;
  }

  List<InlineSpan> parseBoldSegments(String text) {
    final pattern = RegExp(r'〚[^〛]+〛');
    final matches = pattern.allMatches(text);
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: const TextStyle(fontSize: CardDetailConst.fontSize),
          ),
        );
      }

      final boldText = match.group(0)!.replaceAll(RegExp(r'[〚〛]'), '');
      spans.add(
        TextSpan(
          text: boldText,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: CardDetailConst.fontSize,
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(fontSize: CardDetailConst.fontSize),
        ),
      );
    }

    return spans;
  }

  Widget buildTag(String tag) {
    if (tag.startsWith("《") && tag.endsWith("》")) {
      // 《》で囲まれた文字列から《》を除去して中身を取得
      final text = tag.substring(1, tag.length - 1);
      return DiamondTag(text: text);
    }
    if (tag.startsWith("【") && tag.endsWith("】")) {
      // 【】で囲まれた文字列から【】を除去して中身を取得
      final text = tag.substring(1, tag.length - 1);

      // 色単体の判定
      if (text.contains("青")) {
        return _buildSimpleTextTag(text, Colors.blue);
      } else if (text.contains("赤")) {
        return _buildSimpleTextTag(text, Colors.red);
      } else if (text.contains("緑")) {
        return _buildSimpleTextTag(text, Colors.green);
      }
      // その他の【】タグはデフォルトで黒色
      return _buildSimpleTextTag(text, Colors.black);
    }
    if (tag.startsWith("『") && tag.endsWith("』")) {
      // 『』で囲まれた文字列から『』を除去して中身を取得
      final text = tag.substring(1, tag.length - 1);
      return _buildSimpleTextTag(text, Colors.black);
    }
    return _buildFallbackTag(tag);
  }

  Widget _buildSimpleTextTag(
    String label,
    Color color, {
    double widthFactor = 1.3,
  }) {
    return SimpleTextTag(text: label, color: color, widthFactor: widthFactor);
  }

  Widget _buildFallbackTag(String tag) {
    return SizedBox(
      height: CardDetailConst.lineHeight,
      child: Center(
        widthFactor: 1.0,
        child: Text(tag, style: TextStyle(fontSize: CardDetailConst.fontSize)),
      ),
    );
  }
}
