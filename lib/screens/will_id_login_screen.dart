import 'package:flutter/material.dart';
import 'package:will_id_sdk/will_id_sdk.dart';

/// Will ID OAuth 認証用の WebView 画面。
///
/// SDK 提供の WillIdWebView をラップし、本アプリのデザインに合わせた AppBar を付与する。
/// pop 戻り値として WillIdAuthResult を返す。キャンセル / エラー時は null。
class WillIdLoginScreen extends StatelessWidget {
  const WillIdLoginScreen({super.key, this.prompt});

  /// 'login' または 'signup' を指定できる。Will ID 側のプロンプト表示に使われる。
  final String? prompt;

  @override
  Widget build(BuildContext context) {
    final config = WillIdConfig.fromEnvironment();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: Text(prompt == 'signup' ? 'Will ID で新規登録' : 'Will ID でログイン'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: WillIdWebView(
        config: config,
        prompt: prompt,
        onResult: (result) => Navigator.of(context).pop(result),
        onError: (errorCode) => Navigator.of(context).pop(null),
        onCancel: () => Navigator.of(context).pop(null),
      ),
    );
  }
}
