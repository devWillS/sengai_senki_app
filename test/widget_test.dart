import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senkai_sengi/main.dart';

void main() {
  testWidgets('カード一覧画面が表示される', (tester) async {
    await tester.pumpWidget(const SenkaiSengiApp());

    // Allow asynchronous card loading to complete.
    await tester.pumpAndSettle();

    expect(find.text('カード一覧'), findsOneWidget);
    expect(find.textContaining('表示件数'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
