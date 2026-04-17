import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:senkai_sengi/screens/faq_screen.dart';
import 'package:senkai_sengi/screens/will_id_login_screen.dart';
import 'package:senkai_sengi/view_models/auth_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:will_id_sdk/will_id_sdk.dart';

class InfoPortalScreen extends ConsumerWidget {
  const InfoPortalScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLogin(BuildContext context, WidgetRef ref,
      {String prompt = 'login'}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<WillIdAuthResult>(
      MaterialPageRoute(
        builder: (_) => WillIdLoginScreen(prompt: prompt),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    final success =
        await ref.read(authSessionProvider.notifier).loginWithWillIdResult(result);
    messenger.showSnackBar(
      SnackBar(
        content:
            Text(success ? 'tcg_verse と連携しました。デッキを同期しました。' : 'ログインに失敗しました。'),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか?'),
        content: const Text('ローカルのデッキはこのまま残ります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authSessionProvider.notifier).logout();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ログアウトしました。')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          '情報ポータル',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // tcg_verse 移行案内セクション (ログイン前 / 後で表示を切替)
            _TcgVerseMigrationCard(
              session: session,
              theme: theme,
              onLogin: () => _handleLogin(context, ref),
              onLogout: () => _handleLogout(context, ref),
              onDownload: () {
                // tcg_verse アプリのストアリンク。
                // TODO: 本番 tcg_verse のストア URL が決まったら差し替える
                _launchUrl('https://tcg-verse-app.com/');
              },
            ),
            const SizedBox(height: 20),

            // 公式リンクセクション
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha:0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        '千怪戦戯 公式',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LinkTile(
                    icon: Icons.language,
                    title: '公式サイト',
                    subtitle: '最新情報・ルール',
                    onTap: () => _launchUrl('https://www.senkaisengi.com/'),
                    color: Colors.blue[400]!,
                  ),
                  const SizedBox(height: 12),
                  _LinkTile(
                    imagePath: 'assets/icons/x_logo.png',
                    title: '公式 X (旧Twitter)',
                    subtitle: '@senkaisengi',
                    onTap: () => _launchUrl('https://x.com/senkaisengi'),
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 12),
                  _LinkTile(
                    icon: Icons.help_outline,
                    title: 'よくある質問',
                    subtitle: 'ルール・カードに関する質問',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FaqScreen(),
                        ),
                      );
                    },
                    color: Colors.orange[700]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 開発者リンクセクション
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.code, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        '開発者',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LinkTile(
                    imagePath: 'assets/icons/x_logo.png',
                    title: '開発者 X',
                    subtitle: 'アプリに関するお知らせ',
                    onTap: () => _launchUrl('https://x.com/sengi_pocket'),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // その他の情報
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha:0.7),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'アプリバージョン',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  FutureBuilder(
                    future: currentVer(),
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                          return Text(
                            snapshot.data ?? "",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> currentVer() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  }) : assert(
         icon != null || imagePath != null,
         'Either icon or imagePath must be provided',
       );

  final IconData? icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha:0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        width: 20,
                        height: 20,
                        color: color,
                      )
                    : Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// tcg_verse への移行案内 + Will ID ログイン/ログアウトをまとめたカード。
///
/// 未ログイン時は「デッキを tcg_verse アプリと共有できます」訴求、
/// ログイン時は「連携中」情報とログアウトボタンを表示する。
class _TcgVerseMigrationCard extends StatelessWidget {
  const _TcgVerseMigrationCard({
    required this.session,
    required this.theme,
    required this.onLogin,
    required this.onLogout,
    required this.onDownload,
  });

  final dynamic session; // AuthSession? だが import を増やさないため dynamic
  final ThemeData theme;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = session != null;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F6FEB), Color(0xFF2EA043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.swap_horiz, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'tcg_verse 連携',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '千戯ポケットのデッキ管理機能は、マルチTCG対応アプリ '
            '「tcg_verse」 に統合されます。\n'
            'Will ID でログインするとこのアプリのデッキが tcg_verse に同期され、'
            'どちらのアプリでも同じデッキが使えます。',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${session.user.displayName} として連携中',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('ログアウト',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.login),
                label: const Text('Will ID でログインして連携する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1F6FEB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                label: const Text('tcg_verse について',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
