import 'package:flutter/material.dart';
import 'package:will_id_sdk/will_id_sdk.dart';

/// Will ID OAuth 認証用の WebView 画面。
///
/// SDK 提供の WillIdWebView をラップし、本アプリのデザインに合わせた AppBar を付与する。
/// pop 戻り値として WillIdAuthResult を返す。キャンセル / エラー時は null。
///
/// `WillIdConfig.fromEnvironment()` は dart-define が空だと ArgumentError を
/// 投げるため、build 内で try/catch しフォールバック画面を出す。
/// (呼び出し側で `AuthViewModel.isWillIdAvailable` を事前確認するのが推奨)
class WillIdLoginScreen extends StatelessWidget {
  const WillIdLoginScreen({super.key, this.prompt});

  /// 'login' または 'signup' を指定できる。Will ID 側のプロンプト表示に使われる。
  final String? prompt;

  @override
  Widget build(BuildContext context) {
    WillIdConfig? config;
    String? configError;
    try {
      config = WillIdConfig.fromEnvironment();
    } catch (e) {
      configError = e.toString();
    }

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
      body: config == null
          ? _ConfigMissing(error: configError)
          : WillIdWebView(
              config: config,
              prompt: prompt,
              onResult: (result) => Navigator.of(context).pop(result),
              onError: (errorCode) => Navigator.of(context).pop(null),
              onCancel: () => Navigator.of(context).pop(null),
            ),
    );
  }
}

/// dart-define が未設定のビルドで Will ID WebView を開けないときの案内 UI。
class _ConfigMissing extends StatelessWidget {
  const _ConfigMissing({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Will ID が有効になっていません',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'このビルドには Will ID の設定が含まれていません。\n'
              'アプリを最新版に更新するか、開発者に連絡してください。',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
