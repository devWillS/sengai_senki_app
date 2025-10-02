import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senkai_sengi/screens/card_detail_overlay.dart';
import 'package:senkai_sengi/screens/deck_screenshot_screen.dart';
import 'package:senkai_sengi/screens/solo_play_screen.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';
import 'package:senkai_sengi/widgets/cost_curve_chart.dart';

import '../models/card_data.dart';
import '../models/deck.dart';
import '../view_models/deck_detail_view_model.dart';
import 'deck_edit_screen.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  const DeckDetailScreen({super.key, this.deck});

  final Deck? deck;

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  late final DeckDetailViewModel viewModel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    viewModel = DeckDetailViewModel(ref, widget.deck);
    // Delay the provider update to avoid modifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.initFromDeck(widget.deck);
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch the providers for reactive updates
    final mainDeckCards = ref.watch(mainDeckCardsProvider);
    final magicDeckCards = ref.watch(magicDeckCardsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFF3E3E3E),
          appBar: CupertinoNavigationBar(
            backgroundColor: theme.colorScheme.primary,
            leading: CupertinoNavigationBarBackButton(
              color: Colors.white,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            middle: const Text(
              'デッキ詳細',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextField(
                  controller: viewModel.nameController,
                  decoration: const InputDecoration(
                    hintText: 'デッキ名',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  // デッキ編集画面に現在の状態を渡す（プロバイダの状態から現在のデッキを構築）
                  final currentDeck = await _buildCurrentDeck();
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DeckEditScreen(
                        deck: currentDeck,
                        viewModel: viewModel,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      _buildCardGrid(mainDeckCards, 20, isMainDeck: true),
                      const SizedBox(height: 1),
                      _buildCardGrid(magicDeckCards, 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 5,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsetsGeometry.all(5),
                        child: AspectRatio(
                          aspectRatio: 1.5,
                          child: CostCurveChart(deck: viewModel.deck),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsetsGeometry.symmetric(
                          vertical: 5,
                          horizontal: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(Master().typeList.length, (
                            index,
                          ) {
                            final type = Master().typeList[index];
                            final count = viewModel.deck?.typeCount(type) ?? 0;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text("$count"),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _saveDeck();
                },
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('保存')),
                ),
              ),
              viewModel.isSavedInDatabase
                  ? Column(
                      children: [
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CupertinoAlertDialog(
                                      title: const Text("削除しますか？"),
                                      actions: <Widget>[
                                        CupertinoDialogAction(
                                          child: const Text("いいえ"),
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("はい"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldDelete == true) {
                                  final success = await viewModel.deleteDeck();
                                  if (!context.mounted) return;

                                  if (success) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CupertinoAlertDialog(
                                          title: const Text("削除しました"),
                                          actions: <Widget>[
                                            CupertinoDialogAction(
                                              child: const Text("OK"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(
                                                  context,
                                                ).maybePop('deleted');
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('デッキの削除に失敗しました'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Icon(CupertinoIcons.delete),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (viewModel.deck == null) {
                                  return;
                                }
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Scaffold(
                                      backgroundColor: Colors.black45,
                                      body: DeckScreenshotScreen(
                                        deck: viewModel.deck,
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Icon(CupertinoIcons.camera),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final shouldCopy = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CupertinoAlertDialog(
                                      title: const Text("デッキをコピーしますか？"),
                                      content: Text(
                                        "「${viewModel.nameController.text}のコピー」として新しいデッキが作成されます",
                                      ),
                                      actions: <Widget>[
                                        CupertinoDialogAction(
                                          child: const Text("キャンセル"),
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                        ),
                                        CupertinoDialogAction(
                                          isDefaultAction: true,
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("コピー"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldCopy == true) {
                                  final copiedDeck = await viewModel.copyDeck();
                                  if (!context.mounted) return;

                                  if (copiedDeck != null) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CupertinoAlertDialog(
                                          title: const Text("コピーしました"),
                                          content: Text(
                                            "「${copiedDeck.name}」として保存しました",
                                          ),
                                          actions: <Widget>[
                                            CupertinoDialogAction(
                                              child: const Text("OK"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.of(
                                                  context,
                                                ).maybePop('copied');
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('デッキのコピーに失敗しました'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Icon(Icons.content_copy_outlined),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final mainCount = mainDeckCards.length;
                                final magicCount = magicDeckCards.length;

                                if (mainCount != 20 || magicCount != 10) {
                                  await showCupertinoDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => CupertinoAlertDialog(
                                      title: const Text('ソロプレイを開始できません'),
                                      content: Text(
                                        'メインデッキは20枚、魔力デッキは10枚である必要があります。\n'
                                        '現在: メイン $mainCount 枚 / 魔力 $magicCount 枚',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('OK'),
                                          onPressed: () => Navigator.of(dialogContext).pop(),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                final currentDeck = await _buildCurrentDeck();
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SoloPlayScreen(
                                      deck: currentDeck,
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(CupertinoIcons.game_controller),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDeck() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final success = await viewModel.saveDeck();

    if (!mounted) return;

    if (success) {
      setState(() => _isSaving = false);

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('保存しました'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('デッキの保存に失敗しました')));
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!viewModel.hasChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('変更を破棄'),
        content: const Text('変更内容を保存せずに戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('破棄'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showCardDetail(int index, Object tag) {
    final mainDeckCards = ref.read(mainDeckCardsProvider);
    final magicDeckCards = ref.read(magicDeckCardsProvider);

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: CardDetailOverlay(
              initialIndex: index,
              cards: mainDeckCards + magicDeckCards,
              heroTag: tag,
            ),
          );
        },
      ),
    );
  }

  Future<Deck> _buildCurrentDeck() async {
    // プロバイダから現在の状態を取得
    final mainDeckCards = ref.read(mainDeckCardsProvider);
    final magicDeckCards = ref.read(magicDeckCardsProvider);

    // カードをカウント
    final mainCounts = <String, int>{};
    for (final card in mainDeckCards) {
      mainCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
    }

    final magicCounts = <String, int>{};
    for (final card in magicDeckCards) {
      magicCounts.update(card.id, (value) => value + 1, ifAbsent: () => 1);
    }

    // 現在のデッキ情報を使って新しいDeckオブジェクトを作成
    return Deck(
      id: widget.deck?.id ?? "",
      name: viewModel.nameController.text,
      description: viewModel.descriptionController.text,
      mainDeck: mainCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      magicDeck: magicCounts.entries
          .map((e) => DeckCardEntry(cardId: e.key, count: e.value))
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  Widget _buildCardGrid(
    List<CardData> cards,
    int totalSlots, {
    bool isMainDeck = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 670 / 950,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        if (index < cards.length) {
          final card = cards[index];

          return GestureDetector(
            onLongPress: () {
              final mainDeckCards = ref.read(mainDeckCardsProvider);
              _showCardDetail(
                isMainDeck ? index : mainDeckCards.length + index,
                'deck-${card.id}-$index',
              );
            },
            child: Hero(
              tag: 'deck-${card.id}-$index',
              child: CardTile(card: card),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
