import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:senkai_sengi/repositories/card_repository.dart';
import 'package:senkai_sengi/repositories/hive_deck_repository.dart';
import 'package:senkai_sengi/utils/master.dart';

import 'firebase_options.dart';
import 'models/deck_model.dart';
import 'models/deck_sort_type.dart';
import 'models/deck_type.dart';
import 'screens/home_screen.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => throw UnimplementedError(),
);

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

class SenkaiSengiApp extends StatelessWidget {
  const SenkaiSengiApp({super.key, required this.analytics});

  final FirebaseAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '千戯ポケット',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB33333)),
        useMaterial3: true,
      ),
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      home: const HomeScreen(),
    );
  }
}
