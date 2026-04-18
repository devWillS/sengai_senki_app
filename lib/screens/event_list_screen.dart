import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// イベント一覧画面。
///
/// 千戯ポケットでは独自のイベント情報を持っていないため、マルチTCG 対応アプリ
/// 「TCG Verse」に誘導する画面として表示する。TCG Verse では公式カレンダー
/// (Google Calendar) を定期的に取り込んでイベント一覧として提供している。
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  static const _tcgVerseUrl = 'https://tcg-verse-app.com/';

  Future<void> _openTcgVerse() async {
    final uri = Uri.parse(_tcgVerseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.primary,
        middle: const Text(
          'イベント一覧',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ティール系 (cyan-600 → cyan-700) の深い青緑グラデ。
            // アプリの赤いメインカラーの補色寄りでコントラストが強く、
            // イベント画面でも目立つ「案内カード」として機能する。
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
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
                      Icon(Icons.event, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '公認イベント',
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
                    '公認イベントはマルチTCG 対応アプリ 「TCG Verse」 で'
                    'カレンダー表示・検索・ピン留めができます。',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LinkTile(
                    icon: Icons.open_in_new,
                    title: 'TCG Verse で見る',
                    subtitle: '公認イベントカレンダー',
                    onTap: _openTcgVerse,
                    color: Colors.blue[400]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 情報ポータルの _LinkTile と同じスタイルの 1 行リンクカード。
/// 白背景 + 色付きアイコンバッジ + タイトル + サブタイトル + chevron。
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
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
