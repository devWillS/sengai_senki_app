import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'card_list_screen.dart';
import 'deck_list_screen.dart';
import 'info_portal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CupertinoTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = CupertinoTabController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: Colors.white,
        activeColor: theme.colorScheme.primary,
        inactiveColor: theme.colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_module_outlined),
            activeIcon: Icon(Icons.view_module),
            label: 'カード一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark_outlined),
            activeIcon: Icon(Icons.collections_bookmark),
            label: 'デッキ一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: '情報ポータル',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(builder: (_) => const CardListScreen());
          case 1:
            return CupertinoTabView(builder: (_) => const DeckListScreen());
          case 2:
          default:
            return CupertinoTabView(builder: (_) => const InfoPortalScreen());
        }
      },
    );
  }
}
