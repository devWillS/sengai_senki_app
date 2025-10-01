import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:senkai_sengi/repositories/card_repository.dart';
import 'package:senkai_sengi/repositories/hive_deck_repository.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'models/deck_model.dart';
import 'models/deck_sort_type.dart';
import 'models/deck_type.dart';
import 'screens/home_screen.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => throw UnimplementedError(),
);

const appStoreUrl = 'https://apps.apple.com/app/id6753087226';
const playStoreUrl =
    'https://play.google.com/store/apps/details?id=jp.devwill.sengiPocket';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  await analytics.logAppOpen();

  await Hive.initFlutter();

  Hive.registerAdapter(DeckModelAdapter());
  Hive.registerAdapter(DeckSortTypeAdapter());
  Hive.registerAdapter(DeckTypeAdapter());

  Master().cardList = await CardRepository().loadCards();
  // ToDo:サーバー経由で取得できるようにしたい
  Master().colorList = ["赤", "青", "緑"];
  Master().typeList = ["怪魔", "呪文", "付与", "魔力"];
  Master().rarityList = ["N", "R", "SR", "LR"];
  Master().costList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  Master().abilityList = [];

  // 初回起動時にプリセットデッキをインポート
  await HiveDeckRepository.instance.importPresetDecksOnFirstLaunch();

  runApp(
    ProviderScope(
      overrides: [firebaseAnalyticsProvider.overrideWithValue(analytics)],
      child: SenkaiSengiApp(analytics: analytics),
    ),
  );
}

class SenkaiSengiApp extends StatefulWidget {
  const SenkaiSengiApp({super.key, required this.analytics});

  final FirebaseAnalytics analytics;

  @override
  State<SenkaiSengiApp> createState() => _SenkaiSengiAppState();
}

class _SenkaiSengiAppState extends State<SenkaiSengiApp>
    with WidgetsBindingObserver {
  bool _isCheckingUpdate = false;
  bool _isDialogVisible = false;
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForForcedUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForForcedUpdate();
    }
  }

  Future<void> _checkForForcedUpdate() async {
    if (_isCheckingUpdate || _isDialogVisible) return;
    _isCheckingUpdate = true;
    final needUpdate = await _shouldForceUpdate();
    _isCheckingUpdate = false;
    if (!mounted || _isDialogVisible) return;
    if (needUpdate) {
      _isDialogVisible = true;
      await _showForceUpdateDialog();
      _isDialogVisible = false;
    }
  }

  Future<bool> _shouldForceUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.setDefaults(const {
        'min_version': '0.0.0',
        'force_update_url': '',
      });
      await remoteConfig.fetchAndActivate();

      final minVersion = remoteConfig.getString('min_version').trim();
      if (minVersion.isEmpty) {
        return false;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();

      return _isVersionLower(currentVersion, minVersion);
    } catch (e) {
      debugPrint('Remote config fetch failed: $e');
      return false;
    }
  }

  bool _isVersionLower(String current, String minimum) {
    final currentParts = current.split('.');
    final minimumParts = minimum.split('.');
    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length
          ? int.tryParse(currentParts[i]) ?? 0
          : 0;
      final minimumValue = i < minimumParts.length
          ? int.tryParse(minimumParts[i]) ?? 0
          : 0;

      if (currentValue < minimumValue) {
        return true;
      }
      if (currentValue > minimumValue) {
        return false;
      }
    }

    return false;
  }

  Future<void> _showForceUpdateDialog() async {
    final storeUrl = Platform.isAndroid ? playStoreUrl : appStoreUrl;
    final navigatorContext = _rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    await showCupertinoDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('アップデートが必要です'),
        content: const Text('最新バージョンに更新してからお楽しみください。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              if (storeUrl.isNotEmpty) {
                final uri = Uri.tryParse(storeUrl);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('アップデートする'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '千戯ポケット',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB33333)),
        useMaterial3: true,
      ),
      navigatorKey: _rootNavigatorKey,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: widget.analytics),
      ],
      home: const HomeScreen(),
    );
  }
}
