import 'package:flutter/material.dart';

class ColorManager {
  static Color primary = HexColor.from("#DC143C"); // #DC143C
  static Color secondary = HexColor.from("#FFC0CB"); // #FFC0CB

  static List<Color> getColors(String color) {
    const blue = Color(0xFF1E50C8);
    const green = Color(0xFF5ABE5A);
    const red = Color(0xFFED2323);
    final colors = <Color>[];

    for (final letter in color.characters) {
      switch (letter) {
        case "青":
          colors.add(blue);
          break;
        case "緑":
          colors.add(green);
        case "赤":
          colors.add(red);
        case "黄":
        default:
          colors.add(const Color(0xFF1D1615));
      }
    }

    if (colors.length == 1) {
      colors.add(colors.first);
    }

    return colors;
  }
}

extension HexColor on Color {
  static Color from(String hexString) {
    hexString = hexString.replaceAll("#", "");
    if (hexString.length == 6) {
      hexString = "FF$hexString"; // 不透明にする
    }
    return Color(int.parse(hexString, radix: 16));
  }
}
