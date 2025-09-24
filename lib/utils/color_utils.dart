import 'dart:ui';

extension HexColor on Color {
  static Color from(String hexString) {
    hexString = hexString.replaceAll("#", "");
    if (hexString.length == 6) {
      hexString = "FF$hexString"; // 不透明にする
    }
    return Color(int.parse(hexString, radix: 16));
  }
}
