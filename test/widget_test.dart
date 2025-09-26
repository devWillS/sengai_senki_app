import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senkai_sengi/main.dart';

void main() {
  testWidgets('カード一覧画面が表示される', (tester) async {
    await tester.pumpWidget(const SenkaiSengiApp());

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('カード一覧'), findsWidgets);
    expect(find.byIcon(Icons.view_module), findsOneWidget);
  });
}
