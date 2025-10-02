import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/models/deck.dart';
import 'package:senkai_sengi/screens/card_detail_overlay.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';

class SoloPlayScreen extends StatefulWidget {
  const SoloPlayScreen({super.key, required this.deck});

  final Deck deck;

  @override
  State<SoloPlayScreen> createState() => _SoloPlayScreenState();
}

class _SoloPlayScreenState extends State<SoloPlayScreen>
    with TickerProviderStateMixin {
  // ゲームエリア
  List<CardData> _library = [];
  List<CardData> _hand = [];
  List<CardData> _graveyard = [];
  List<CardData> _magicDeck = [];
  List<CardData> _wallZone = []; // ウォールゾーンのカード

  // 3つのレーンごとのカードを管理
  // 各レーン: [怪魔カード(1枚), ...付与カード(複数)]
  List<List<CardData>> _lanes = [[], [], []];

  // カードの回転状態管理（true: アップ、false: ダウン）
  // レーンカード用: _laneCardRotations[laneIndex][cardIndex]
  List<List<bool>> _laneCardRotations = [[], [], []];
  // 魔力カード用
  List<bool> _magicCardRotations = [];
  // 魔力カードの表裏状態管理（true: 表向き、false: 裏向き）
  List<bool> _magicCardFaceUp = [];
  // フリップアニメーション用のAnimationController
  List<AnimationController> _flipAnimationControllers = [];

  // ゲーム状態
  bool _isGameStarted = false;
  int _turnCount = 0;
  bool _isFirstPlayer = true; // true: 先攻, false: 後攻
  bool _isLibraryTopCardFaceUp = false;
  bool _isMagicDeckTopCardFaceUp = false;
  late final AnimationController _libraryFlipController;
  late final AnimationController _magicDeckFlipController;

  List<CardData> _magicZone = []; // 魔力ゾーンのカード

  @override
  void initState() {
    super.initState();
    _libraryFlipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _magicDeckFlipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeGame();
  }

  @override
  void dispose() {
    for (final controller in _flipAnimationControllers) {
      controller.dispose();
    }
    _libraryFlipController.dispose();
    _magicDeckFlipController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // メインデッキをライブラリとして初期化
    final mainDeck = <CardData>[];
    for (final entry in widget.deck.mainDeck) {
      final card = Master().cardList.firstWhere((c) => c.id == entry.cardId);
      for (int i = 0; i < entry.count; i++) {
        mainDeck.add(card);
      }
    }

    // 魔法デッキを初期化
    final magicDeck = <CardData>[];
    for (final entry in widget.deck.magicDeck) {
      final card = Master().cardList.firstWhere((c) => c.id == entry.cardId);
      for (int i = 0; i < entry.count; i++) {
        magicDeck.add(card);
      }
    }

    setState(() {
      _library = mainDeck;
      _magicDeck = magicDeck;
      _hand = [];
      _graveyard = [];
      _wallZone = [];
      _magicZone = [];
      _lanes = [[], [], []];
      _laneCardRotations = [[], [], []];
      _magicCardRotations = [];
      _magicCardFaceUp = [];
      _isLibraryTopCardFaceUp = false;
      _isMagicDeckTopCardFaceUp = false;

      // 既存のアニメーションコントローラーを破棄
      for (final controller in _flipAnimationControllers) {
        controller.dispose();
      }
      _flipAnimationControllers = [];
      _isGameStarted = false;
      _turnCount = 0;
    });

    _libraryFlipController.reset();
    _magicDeckFlipController.reset();
  }

  void _startGame() {
    setState(() {
      _shuffleDeck();
      _shuffleMagicDeck();
      // ウォールゾーンに4枚配置
      _placeWallCards();
      // 初期手札4枚ドロー
      _drawCards(4);
      _isGameStarted = true;
      _turnCount = 1;

      _upPhase();
      _drawPhase();
      _setPhase();
    });
  }

  void _placeWallCards() {
    // メインデッキから4枚をウォールゾーンに配置
    for (int i = 0; i < 4 && _library.isNotEmpty; i++) {
      _wallZone.add(_library.removeAt(0));
    }
    _isLibraryTopCardFaceUp = false;
    _libraryFlipController.reset();
    _isMagicDeckTopCardFaceUp = false;
    _magicDeckFlipController.reset();
  }

  void _shuffleDeck() {
    final random = Random();
    _library.shuffle(random);
    _isLibraryTopCardFaceUp = false;
    _libraryFlipController.reset();
  }

  void _shuffleMagicDeck() {
    final random = Random();
    _magicDeck.shuffle(random);
    _isMagicDeckTopCardFaceUp = false;
    _magicDeckFlipController.reset();
  }

  void _drawCards(int count) {
    for (int i = 0; i < count && _library.isNotEmpty; i++) {
      setState(() {
        final drawnCard = _library.removeAt(0);
        _hand.add(drawnCard);
        _isLibraryTopCardFaceUp = false;
      });
      _libraryFlipController.reset();
    }
  }

  void _addMagicCardToZone(
    CardData card, {
    bool faceUp = true,
    bool isUpright = true,
  }) {
    _magicZone.add(card);
    _magicCardRotations.add(isUpright);
    _magicCardFaceUp.add(faceUp);

    final flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0;
    _flipAnimationControllers.add(flipController);
  }

  CardData _removeMagicCardFromZone(int index) {
    final removedCard = _magicZone.removeAt(index);
    if (_magicCardRotations.length > index) {
      _magicCardRotations.removeAt(index);
    }
    if (_magicCardFaceUp.length > index) {
      _magicCardFaceUp.removeAt(index);
    }
    if (_flipAnimationControllers.length > index) {
      final controller = _flipAnimationControllers.removeAt(index);
      controller.dispose();
    }
    return removedCard;
  }

  void _playCard(int handIndex) {
    if (handIndex < _hand.length) {
      final card = _hand[handIndex];

      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('カードをプレイ'),
          message: Text('${card.name}をどこに配置しますか？'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _placeCardInLane(handIndex, 0);
              },
              child: const Text('左レーンに配置'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _placeCardInLane(handIndex, 1);
              },
              child: const Text('中央レーンに配置'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _placeCardInLane(handIndex, 2);
              },
              child: const Text('右レーンに配置'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _discardCard(handIndex);
              },
              child: const Text('捨て札に送る'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
        ),
      );
    }
  }

  void _placeCardInLane(int handIndex, int laneIndex) {
    if (handIndex < _hand.length) {
      final card = _hand[handIndex];

      // カードタイプを判定（仮実装：コストが高いカードを怪魔カードとする）
      bool isMonsterCard = card.type == "怪魔"; // 怪魔カードの判定条件（要調整）

      setState(() {
        if (isMonsterCard && _lanes[laneIndex].isNotEmpty) {
          // 怪魔カードで既に怪魔カードがある場合、置き換え確認
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('カードの置き換え'),
              content: Text(
                '${_getLaneName(laneIndex)}の怪魔カードを${card.name}に置き換えますか？',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('キャンセル'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('置き換える'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      // 既存の怪魔カードを捨て札へ
                      _graveyard.add(_lanes[laneIndex][0]);
                      _lanes[laneIndex][0] = _hand.removeAt(handIndex);
                      _laneCardRotations[laneIndex][0] = true; // 新しいカードはアップ
                    });
                  },
                ),
              ],
            ),
          );
        } else if (isMonsterCard) {
          // 怪魔カードで空きレーンの場合
          _lanes[laneIndex].insert(0, _hand.removeAt(handIndex));
          _laneCardRotations[laneIndex].insert(0, true); // 初期状態はアップ
        } else {
          // 付与カードの場合
          if (_lanes[laneIndex].isEmpty) {
            // レーンが空の場合は配置できない
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('配置できません'),
                content: const Text('付与カードは怪魔カードがいるレーンにのみ配置できます'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          } else {
            // 付与カードを追加
            _lanes[laneIndex].add(_hand.removeAt(handIndex));
            _laneCardRotations[laneIndex].add(true); // 初期状態はアップ
          }
        }
      });
    }
  }

  void _discardCard(int handIndex) {
    if (handIndex < _hand.length) {
      setState(() {
        final card = _hand.removeAt(handIndex);
        _graveyard.add(card);
      });
    }
  }

  // フェーズ処理
  void _nextPhase() {
    setState(() {
      _endPhase();
      _turnCount++;
      _upPhase();
      _drawPhase();
      _setPhase();
    });
  }

  void _upPhase() {
    // 1.アップフェーズ：自分の怪魔を、魔力を全てアップ（タテ向きに）する
    setState(() {
      // 各レーンのすべてのカードをアップ状態に
      for (int laneIndex = 0; laneIndex < 3; laneIndex++) {
        for (
          int cardIndex = 0;
          cardIndex < _laneCardRotations[laneIndex].length;
          cardIndex++
        ) {
          _laneCardRotations[laneIndex][cardIndex] = true;
        }
      }

      // 魔力カードをすべてアップ状態に
      for (int i = 0; i < _magicCardRotations.length; i++) {
        _magicCardRotations[i] = true;
      }
    });
  }

  void _drawPhase() {
    // 2.ドローフェーズ：メインデッキの上から一枚引く
    _drawCards(1);
  }

  void _setPhase() {
    // 3.セットフェーズ：魔力デッキの上から魔力を2つ（先攻１ターン目は1つ）、アップで魔力ゾーンに置く
    int magicCards = (_isFirstPlayer && _turnCount == 1) ? 1 : 2;
    for (int i = 0; i < magicCards && _magicDeck.isNotEmpty; i++) {
      final card = _magicDeck.removeAt(0);
      _addMagicCardToZone(card);
      _isMagicDeckTopCardFaceUp = false;
      _magicDeckFlipController.reset();
    }
  }

  void _endPhase() {
    // エンドフェーズの処理（必要に応じて）
  }

  void _resetGame() {
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _confirmBackNavigation,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF3E3E3E),
          appBar: CupertinoNavigationBar(
            backgroundColor: theme.colorScheme.primary,
            leading: CupertinoNavigationBarBackButton(
              color: Colors.white,
              onPressed: () async {
                final shouldPop =
                    !_isGameStarted || await _confirmBackNavigation();
                if (!context.mounted) return;
                if (shouldPop) {
                  Navigator.of(context).pop();
                }
              },
            ),
            middle: Text(
              'ソロプレイ',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('ゲームをリセット'),
                    content: const Text('新しいゲームを開始しますか？'),
                    actions: [
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('リセット'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetGame();
                        },
                      ),
                      CupertinoDialogAction(
                        child: const Text('キャンセル'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          body: _isGameStarted ? _buildGameArea() : _buildStartScreen(),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'デッキ: ${widget.deck.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'メインデッキ: ${_library.length}枚',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              '魔法デッキ: ${_magicDeck.length}枚',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            // 先攻・後攻選択
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '先攻・後攻を選択',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [Text('先攻')],
                        ),
                        selected: _isFirstPlayer,
                        onSelected: (selected) {
                          setState(() {
                            _isFirstPlayer = true;
                          });
                        },
                        selectedColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: _isFirstPlayer ? Colors.white : Colors.black,
                        ),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [Text('後攻')],
                        ),
                        selected: !_isFirstPlayer,
                        onSelected: (selected) {
                          setState(() {
                            _isFirstPlayer = false;
                          });
                        },
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: !_isFirstPlayer ? Colors.white : Colors.black,
                        ),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: Text('ゲーム開始（${_isFirstPlayer ? "先攻" : "後攻"}）'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // ゲーム情報（最上部）
            _buildGameInfo(),
            // プレイマットとカード配置エリア
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  // プレイマット背景
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1306 / 920, // プレイマット画像のアスペクト比
                      child: Image.asset(
                        'assets/images/playmat_black.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // プレイマットに合わせたカード配置
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1306 / 920,
                      child: LayoutBuilder(
                        builder: (context, playmatConstraints) {
                          return Stack(
                            children: [
                              // 上部レーン（3つの攻撃ゾーン）
                              Positioned(
                                top: 0,
                                left: playmatConstraints.maxWidth * 0.17,
                                right: playmatConstraints.maxWidth * 0.17,
                                height: playmatConstraints.maxHeight * 0.535,
                                child: _buildLanes(playmatConstraints),
                              ),
                              // 左側：ウォールゾーン
                              Positioned(
                                left: -playmatConstraints.maxHeight * 0.065,
                                top: playmatConstraints.maxHeight * 0.05,
                                width: playmatConstraints.maxWidth * 0.25,
                                height: playmatConstraints.maxHeight * 0.42,
                                child: _buildWallZone(playmatConstraints),
                              ),
                              // 左下：魔力デッキ
                              Positioned(
                                left: playmatConstraints.maxWidth * 0.026,
                                bottom: playmatConstraints.maxHeight * 0.175,
                                height: playmatConstraints.maxWidth * 0.2,
                                child: _buildMagicDeck(playmatConstraints),
                              ),
                              // 右側：メインデッキ
                              Positioned(
                                right: playmatConstraints.maxWidth * 0.025,
                                top: playmatConstraints.maxHeight * 0.185,
                                height: playmatConstraints.maxWidth * 0.2,
                                child: _buildMainDeck(playmatConstraints),
                              ),
                              // 下部中央：魔力ゾーン（プレイマット上の表示用）
                              Positioned(
                                left: playmatConstraints.maxWidth * 0.225,
                                bottom: playmatConstraints.maxHeight * 0.035,
                                right: playmatConstraints.maxWidth * 0.225,
                                height: playmatConstraints.maxHeight * 0.44,
                                child: _buildMagicZoneIndicator(),
                              ),
                              // 右下：捨て札
                              Positioned(
                                right: 0,
                                bottom: playmatConstraints.maxHeight * 0.035,
                                width: playmatConstraints.maxWidth * 0.17,
                                height: playmatConstraints.maxHeight * 0.43,
                                child: _buildGraveyard(playmatConstraints),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 手札エリア（プレイマットの下）
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildHandArea(),
              ),
            ),
            // アクションボタン（最下部）
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildActions(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameInfo() {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isFirstPlayer ? Colors.blue : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isFirstPlayer ? '先攻' : '後攻',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ターン: $_turnCount',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 上部レーン（3つの攻撃ゾーン）
  Widget _buildLanes(BoxConstraints playmatConstraints) {
    return Row(
      children: List.generate(3, (index) {
        final laneCards = _lanes[index];
        return Expanded(
          child: laneCards.isEmpty
              ? Container()
              : _buildLaneStack(laneCards, playmatConstraints, index),
        );
      }),
    );
  }

  // レーン内のカードスタックを構築
  Widget _buildLaneStack(
    List<CardData> laneCards,
    BoxConstraints constraints,
    int laneIndex,
  ) {
    double cardHeight = constraints.maxWidth * 0.2;
    double overlapOffset = 15.0; // 付与カードのずれ量

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 付与カード（下にずれて表示）
        ...List.generate(laneCards.length > 1 ? laneCards.length - 1 : 0, (
          index,
        ) {
          final attachmentIndex = index + 1;
          final isRotated =
              _laneCardRotations[laneIndex].length > attachmentIndex
              ? _laneCardRotations[laneIndex][attachmentIndex]
              : true;

          return Positioned(
            top: overlapOffset * (index + 1), // 怪魔カードの下にずれて配置
            child: GestureDetector(
              onTap: () =>
                  _showCardActionSheet(laneIndex, attachmentIndex, false),
              onLongPress: () => _showCardDetail(
                _lanes[laneIndex][attachmentIndex],
                heroTag: 'lane_${laneIndex}_attachment_$attachmentIndex',
              ),
              child: AnimatedRotation(
                turns: isRotated ? 0 : -0.25, // 90度回転
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: cardHeight,
                    width: cardHeight * 670 / 950,
                    child: CardTile(
                      card: laneCards[attachmentIndex],
                      heroTag: 'lane_${laneIndex}_attachment_$attachmentIndex',
                    ),
                  ),
                ),
              ),
            ),
          );
        }).reversed,

        // 怪魔カード（上部・最前面）
        if (laneCards.isNotEmpty)
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => _showCardActionSheet(laneIndex, 0, false),
              onLongPress: () => _showCardDetail(
                _lanes[laneIndex][0],
                heroTag: 'lane_${laneIndex}_monster',
              ),
              child: AnimatedRotation(
                turns: _laneCardRotations[laneIndex].isNotEmpty
                    ? (_laneCardRotations[laneIndex][0] ? 0 : -0.25)
                    : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: cardHeight,
                    width: cardHeight * 670 / 950,
                    child: CardTile(
                      card: laneCards[0],
                      heroTag: 'lane_${laneIndex}_monster',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // カードのアクションシートを表示
  void _showCardActionSheet(int laneIndex, int cardIndex, bool isMagicCard) {
    final CardData card = isMagicCard
        ? _magicZone[cardIndex]
        : _lanes[laneIndex][cardIndex];

    final bool isCurrentlyUp = isMagicCard
        ? (_magicCardRotations.length > cardIndex
              ? _magicCardRotations[cardIndex]
              : true)
        : (_laneCardRotations[laneIndex].length > cardIndex
              ? _laneCardRotations[laneIndex][cardIndex]
              : true);

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('カード操作'),
        message: Text('${card.name}の状態を変更しますか？'),
        actions: [
          if (isCurrentlyUp)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _rotateCard(laneIndex, cardIndex, isMagicCard, false);
              },
              child: const Text('ダウン（ヨコ向き）にする'),
            ),
          if (!isCurrentlyUp)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _rotateCard(laneIndex, cardIndex, isMagicCard, true);
              },
              child: const Text('アップ（タテ向き）にする'),
            ),
          if (isMagicCard) ...[
            if (_magicCardFaceUp.length > cardIndex &&
                _magicCardFaceUp[cardIndex])
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _flipMagicCard(cardIndex, false);
                },
                child: const Text('裏向きにする'),
              ),
            if (_magicCardFaceUp.length > cardIndex &&
                !_magicCardFaceUp[cardIndex])
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _flipMagicCard(cardIndex, true);
                },
                child: const Text('表向きにする'),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  if (_magicZone.length > cardIndex) {
                    final cardToDeck = _magicZone.removeAt(cardIndex);
                    if (_magicCardRotations.length > cardIndex) {
                      _magicCardRotations.removeAt(cardIndex);
                    }
                    if (_magicCardFaceUp.length > cardIndex) {
                      _magicCardFaceUp.removeAt(cardIndex);
                    }
                    if (_flipAnimationControllers.length > cardIndex) {
                      final controller = _flipAnimationControllers.removeAt(
                        cardIndex,
                      );
                      controller.dispose();
                    }

                    _magicDeck.insert(0, cardToDeck);
                    _isMagicDeckTopCardFaceUp = false;
                    _magicDeckFlipController.reset();
                  }
                });
              },
              child: const Text('魔力デッキの上に裏向きで移す'),
            ),
          ],
          if (!isMagicCard)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  if (_lanes[laneIndex].length > cardIndex) {
                    final cardToHand = _lanes[laneIndex].removeAt(cardIndex);
                    if (_laneCardRotations[laneIndex].length > cardIndex) {
                      _laneCardRotations[laneIndex].removeAt(cardIndex);
                    }

                    // 怪魔カード（インデックス0）を手札へ戻した場合、
                    // その下の付与カードは捨て札へ移動
                    if (cardIndex == 0 && _lanes[laneIndex].isNotEmpty) {
                      _graveyard.addAll(_lanes[laneIndex]);
                      _lanes[laneIndex].clear();
                      _laneCardRotations[laneIndex].clear();
                    }

                    _hand.add(cardToHand);
                  }
                });
              },
              child: const Text('手札に移す'),
            ),
          if (!isMagicCard)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  if (_lanes[laneIndex].length > cardIndex) {
                    final cardToDeck = _lanes[laneIndex].removeAt(cardIndex);
                    if (_laneCardRotations[laneIndex].length > cardIndex) {
                      _laneCardRotations[laneIndex].removeAt(cardIndex);
                    }

                    if (cardIndex == 0 && _lanes[laneIndex].isNotEmpty) {
                      _graveyard.addAll(_lanes[laneIndex]);
                      _lanes[laneIndex].clear();
                      _laneCardRotations[laneIndex].clear();
                    }

                    _library.insert(0, cardToDeck);
                    _isLibraryTopCardFaceUp = false;
                    _libraryFlipController.reset();
                  }
                });
              },
              child: const Text('メインデッキの上に裏向きで移す'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _moveCardToGraveyard(laneIndex, cardIndex, isMagicCard);
            },
            child: const Text('捨て札に送る'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // カードを回転
  void _rotateCard(int laneIndex, int cardIndex, bool isMagicCard, bool toUp) {
    setState(() {
      if (isMagicCard) {
        if (_magicCardRotations.length > cardIndex) {
          _magicCardRotations[cardIndex] = toUp;
        }
      } else {
        if (_laneCardRotations[laneIndex].length > cardIndex) {
          _laneCardRotations[laneIndex][cardIndex] = toUp;
        }
      }
    });
  }

  // カードを捨て札に移動
  void _moveCardToGraveyard(int laneIndex, int cardIndex, bool isMagicCard) {
    setState(() {
      if (isMagicCard) {
        final removedCard = _removeMagicCardFromZone(cardIndex);
        _graveyard.add(removedCard);
      } else {
        _graveyard.add(_lanes[laneIndex].removeAt(cardIndex));
        _laneCardRotations[laneIndex].removeAt(cardIndex);
      }
    });
  }

  // カードの詳細オーバーレイを表示
  void _showCardDetail(CardData card, {Object? heroTag}) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return CardDetailOverlay(
            initialIndex: 0,
            cards: [card],
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showMainDeckActionSheet() {
    final bool hasCards = _library.isNotEmpty;

    if (!hasCards) {
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('メインデッキ'),
        message: hasCards
            ? Text("残り${_library.length}枚")
            : const Text('デッキが空です'),
        actions: [
          if (hasCards)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _drawCards(1);
              },
              child: const Text('手札に加える'),
            ),
          if (hasCards)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await _toggleLibraryTopCardFace();
              },
              child: Text(
                _isLibraryTopCardFaceUp ? '一番上のカードを裏向きにする' : '一番上のカードを表向きにする',
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _shuffleDeck();
              });
            },
            child: const Text('デッキをシャッフルする'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // ウォールゾーンカードのアクションシートを表示
  void _showWallCardActionSheet(int cardIndex) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('ウォールカード'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showWallCardDialog(cardIndex);
            },
            child: const Text('破壊する'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // ウォールカードを表示するダイアログ
  void _showWallCardDialog(int cardIndex) {
    final card = _wallZone[cardIndex];
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('ウォールカード'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CardTile(
                card: card,
                heroTag: 'wall_card_dialog_$cardIndex',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _moveWallCardToGraveyard(cardIndex);
            },
            child: const Text('捨て札に送る'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _moveWallCardToHand(cardIndex);
            },
            child: const Text('手札に加える'),
          ),
        ],
      ),
    );
  }

  // ウォールカードを捨て札に送る
  void _moveWallCardToGraveyard(int cardIndex) {
    setState(() {
      final card = _wallZone.removeAt(cardIndex);
      _graveyard.add(card);
    });
  }

  // ウォールカードを手札に加える
  void _moveWallCardToHand(int cardIndex) {
    setState(() {
      final card = _wallZone.removeAt(cardIndex);
      _hand.add(card);
    });
  }

  // レーンインデックスから名前を取得
  String _getLaneName(int laneIndex) {
    switch (laneIndex) {
      case 0:
        return '左レーン';
      case 1:
        return '中央レーン';
      case 2:
        return '右レーン';
      default:
        return 'レーン${laneIndex + 1}';
    }
  }

  // 魔力カードの表裏を切り替える
  void _flipMagicCard(int cardIndex, bool faceUp) async {
    if (_flipAnimationControllers.length > cardIndex) {
      final controller = _flipAnimationControllers[cardIndex];

      // 前半: カードを横向きに縮める（90度回転まで）
      await controller.animateTo(0.5);

      // 中間で表裏状態を切り替え
      setState(() {
        if (_magicCardFaceUp.length > cardIndex) {
          _magicCardFaceUp[cardIndex] = faceUp;
        }
      });

      // 後半: カードを元のサイズに戻す
      await controller.animateTo(1.0);

      // アニメーション完了後にリセット
      controller.reset();
    }
  }

  Future<void> _toggleLibraryTopCardFace() async {
    if (_library.isEmpty || _libraryFlipController.isAnimating) {
      return;
    }

    await _libraryFlipController.animateTo(0.5);

    setState(() {
      _isLibraryTopCardFaceUp = !_isLibraryTopCardFaceUp;
    });

    await _libraryFlipController.animateTo(1.0);
    _libraryFlipController.reset();
  }

  Future<void> _toggleMagicDeckTopCardFace() async {
    if (_magicDeck.isEmpty || _magicDeckFlipController.isAnimating) {
      return;
    }

    await _magicDeckFlipController.animateTo(0.5);

    setState(() {
      _isMagicDeckTopCardFaceUp = !_isMagicDeckTopCardFaceUp;
    });

    await _magicDeckFlipController.animateTo(1.0);
    _magicDeckFlipController.reset();
  }

  // ウォールゾーン - 重なり表示
  Widget _buildWallZone(BoxConstraints playmatConstraints) {
    return _wallZone.isEmpty
        ? Container()
        : _buildOverlappingWallCards(playmatConstraints);
  }

  Widget _buildOverlappingWallCards(BoxConstraints playmatConstraints) {
    if (_wallZone.isEmpty) return const SizedBox();

    // カード1枚あたりの高さとオーバーラップ量を計算
    double cardHeight = playmatConstraints.maxWidth * 0.2;
    // double overlapOffset = 20.0; // カードが重なる量
    double overlapOffset = playmatConstraints.maxHeight * 0.075; // カードが重なる量
    // const double overlapLeftOffset = -5.0; // カードが重なる量
    double overlapLeftOffset = -playmatConstraints.maxWidth * 0.013;
    final double totalHeight =
        cardHeight + (overlapOffset * (_wallZone.length - 1));

    return SizedBox(
      height: totalHeight.clamp(0, double.infinity),
      child: Stack(
        children: List.generate(_wallZone.length, (index) {
          final double topOffset = index * overlapOffset;
          final double leftOffset = index * overlapLeftOffset;

          return Positioned(
            bottom: topOffset,
            left: leftOffset,
            child: GestureDetector(
              onTap: () => _showWallCardActionSheet(index),
              child: RotatedBox(
                quarterTurns: -1,
                child: SizedBox(
                  height: cardHeight,
                  width: cardHeight / 950 * 670,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cardHeight / 1407 * 30),
                    child: AspectRatio(
                      aspectRatio: 670 / 950,
                      child: Image.asset(
                        'assets/images/main_card_back.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 捨て札の詳細を表示
  void _showGraveyardDetail() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '捨て札 (${_graveyard.length}枚)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withValues(alpha:0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _graveyard.isEmpty
                    ? const Center(
                        child: Text(
                          '捨て札にカードがありません',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 670 / 950,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: _graveyard.length,
                        itemBuilder: (context, index) {
                          final card = _graveyard[index];
                          return GestureDetector(
                            onTap: () => _showGraveyardCardActionSheet(index),
                            onLongPress: () => _showCardDetail(
                              card,
                              heroTag: 'graveyard_detail_$index',
                            ),
                            child: CardTile(
                              card: card,
                              heroTag: 'graveyard_detail_$index',
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGraveyardCardActionSheet(int index) {
    if (index < 0 || index >= _graveyard.length) {
      return;
    }

    final CardData card = _graveyard[index];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(card.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (index >= 0 && index < _graveyard.length) {
                  final removedCard = _graveyard.removeAt(index);
                  _hand.add(removedCard);
                }
              });
            },
            child: const Text('手札に移す'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _showGraveyardActionSheet() {
    if (_graveyard.isEmpty) {
      return;
    }

    final CardData topCard = _graveyard.last;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('捨て札（${_graveyard.length}枚）'),
        message: Text('トップ: ${topCard.name}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final card = _graveyard.removeLast();
                _hand.add(card);
              });
            },
            child: const Text('手札に移す'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showGraveyardDetail();
            },
            child: const Text('捨て札を確認する'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _showMagicDeckActionSheet() {
    if (_magicDeck.isEmpty) {
      return;
    }

    final topCard = _magicDeck.first;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('魔力デッキ'),
        message: Text(
          _isMagicDeckTopCardFaceUp
              ? '一番上: ${topCard.name}（表向き）'
              : '一番上: ${topCard.name}（裏向き）',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleMagicDeckTopCardFace();
            },
            child: Text(
              _isMagicDeckTopCardFaceUp ? '一番上のカードを裏向きにする' : '一番上のカードを表向きにする',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final card = _magicDeck.removeAt(0);
                _addMagicCardToZone(card);
                _isMagicDeckTopCardFaceUp = false;
                _magicDeckFlipController.reset();
              });
            },
            child: const Text('魔力ゾーンに追加する'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  // 魔力デッキ
  Widget _buildMagicDeck(BoxConstraints playmatConstraints) {
    double cardHeight = playmatConstraints.maxWidth * 0.2;
    return GestureDetector(
      onTap: _showMagicDeckActionSheet,
      onLongPress: _magicDeck.isNotEmpty && _isMagicDeckTopCardFaceUp
          ? () => _showCardDetail(
              _magicDeck.first,
              heroTag: 'magic_deck_top_card',
            )
          : null,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: _magicDeck.isEmpty
            ? AspectRatio(aspectRatio: 670 / 950, child: Container())
            : ClipRRect(
                borderRadius: BorderRadius.circular(cardHeight / 1407 * 30),
                child: AspectRatio(
                  aspectRatio: 670 / 950,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_magicDeck.length > 1)
                        Image.asset(
                          'assets/images/power_card_back.png',
                          fit: BoxFit.cover,
                        ),
                      AnimatedBuilder(
                        animation: _magicDeckFlipController,
                        builder: (context, child) {
                          final double flipValue =
                              _magicDeckFlipController.value;
                          double scaleX;
                          if (flipValue <= 0.5) {
                            scaleX = 1.0 - (flipValue * 2);
                          } else {
                            scaleX = (flipValue - 0.5) * 2;
                          }
                          scaleX = scaleX.clamp(0.0, 1.0);

                          final Widget topCard = _isMagicDeckTopCardFaceUp
                              ? CardTile(
                                  card: _magicDeck.first,
                                  heroTag: 'magic_deck_top_card',
                                )
                              : Image.asset(
                                  'assets/images/power_card_back.png',
                                  fit: BoxFit.cover,
                                );

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              scaleX,
                              1.0,
                              1.0,
                            ),
                            child: topCard,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // メインデッキ
  Widget _buildMainDeck(BoxConstraints playmatConstraints) {
    double cardHeight = playmatConstraints.maxWidth * 0.2;
    return GestureDetector(
      onTap: _showMainDeckActionSheet,
      onLongPress: _library.isNotEmpty && _isLibraryTopCardFaceUp
          ? () => _showCardDetail(_library.first, heroTag: 'library_top_card')
          : null,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: _library.isEmpty
            ? AspectRatio(aspectRatio: 670 / 950, child: Container())
            : ClipRRect(
                borderRadius: BorderRadius.circular(cardHeight / 1407 * 30),
                child: AspectRatio(
                  aspectRatio: 670 / 950,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_library.length > 1)
                        Image.asset(
                          'assets/images/main_card_back.png',
                          fit: BoxFit.cover,
                        ),
                      AnimatedBuilder(
                        animation: _libraryFlipController,
                        builder: (context, child) {
                          final double flipValue = _libraryFlipController.value;
                          double scaleX;
                          if (flipValue <= 0.5) {
                            scaleX = 1.0 - (flipValue * 2);
                          } else {
                            scaleX = (flipValue - 0.5) * 2;
                          }
                          scaleX = scaleX.clamp(0.0, 1.0);

                          final Widget topCard = _isLibraryTopCardFaceUp
                              ? CardTile(
                                  card: _library.first,
                                  heroTag: 'library_top_card',
                                )
                              : Image.asset(
                                  'assets/images/main_card_back.png',
                                  fit: BoxFit.cover,
                                );

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              scaleX,
                              1.0,
                              1.0,
                            ),
                            child: topCard,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 魔力ゾーン（プレイマット上の表示）
  Widget _buildMagicZoneIndicator() {
    return Center(
      child: Column(
        children: [
          Expanded(
            child: _magicZone.isEmpty
                ? Container()
                : GridView.builder(
                    padding: const EdgeInsets.all(2),
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 1行に5枚まで
                          childAspectRatio: 670 / 950,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                        ),
                    itemCount: _magicZone.length,
                    itemBuilder: (context, index) {
                      final card = _magicZone[index];
                      return GestureDetector(
                        onTap: () => _showCardActionSheet(-1, index, true),
                        onLongPress:
                            (_magicCardFaceUp.length > index &&
                                _magicCardFaceUp[index])
                            ? () => _showCardDetail(
                                _magicZone[index],
                                heroTag: 'magic_zone_$index',
                              )
                            : null,
                        child: AnimatedRotation(
                          turns: _magicCardRotations.length > index
                              ? (_magicCardRotations[index] ? 0 : -0.25)
                              : 0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedBuilder(
                            animation: _flipAnimationControllers.length > index
                                ? _flipAnimationControllers[index]
                                : kAlwaysCompleteAnimation,
                            builder: (context, child) {
                              final flipValue =
                                  _flipAnimationControllers.length > index
                                  ? _flipAnimationControllers[index].value
                                  : 0.0;

                              // フリップアニメーション計算を修正
                              // 0.0 = 完全表示, 0.5 = 完全非表示, 1.0 = 完全表示
                              double scaleX;
                              if (flipValue <= 0.5) {
                                // 前半: 1.0 → 0.0 (縮む)
                                scaleX = 1.0 - (flipValue * 2);
                              } else {
                                // 後半: 0.0 → 1.0 (戻る)
                                scaleX = (flipValue - 0.5) * 2;
                              }
                              scaleX = scaleX.clamp(0.0, 1.0);

                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.diagonal3Values(
                                  scaleX,
                                  1.0,
                                  1.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: Colors.purple.withValues(alpha:0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child:
                                      _magicCardFaceUp.length > index &&
                                          !_magicCardFaceUp[index]
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 670 / 950,
                                            child: Image.asset(
                                              'assets/images/power_card_back.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : CardTile(
                                          card: card,
                                          heroTag: 'magic_zone_$index',
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 手札エリア（プレイマット下部）
  Widget _buildHandArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pan_tool, color: Colors.orange[300], size: 20),
              const SizedBox(width: 8),
              Text(
                '手札 (${_hand.length}枚)',
                style: TextStyle(color: Colors.orange[300], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _hand.isEmpty
                ? Center(
                    child: Text(
                      'カードがありません',
                      style: TextStyle(color: Colors.orange[200], fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _hand.length,
                    itemBuilder: (context, index) {
                      final card = _hand[index];
                      return GestureDetector(
                        onTap: () => _playCard(index),
                        onLongPress: () =>
                            _showCardDetail(card, heroTag: 'hand_$index'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: CardTile(card: card, heroTag: 'hand_$index'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 捨て札
  Widget _buildGraveyard(BoxConstraints playmatConstraints) {
    double cardHeight = playmatConstraints.maxWidth * 0.2;
    return GestureDetector(
      onTap: _graveyard.isNotEmpty ? _showGraveyardActionSheet : null,
      onLongPress: _graveyard.isNotEmpty
          ? () => _showCardDetail(_graveyard.last, heroTag: 'graveyard_top')
          : null,
      child: Center(
        child: _graveyard.isEmpty
            ? Container()
            : SizedBox(
                height: cardHeight,
                child: AspectRatio(
                  aspectRatio: 670 / 950,
                  child: CardTile(
                    card: _graveyard.last,
                    heroTag: 'graveyard_top',
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _showEndTurnDialog,
            icon: const Icon(Icons.skip_next, size: 16),
            label: Text('ターン終了', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndTurnDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('ターン終了'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              _isFirstPlayer ? '自分のターンを終了します。よろしいですか？' : '相手のターンへ移ります。よろしいですか？',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _nextPhase();
            },
            child: const Text('ターン終了'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmBackNavigation() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('確認'),
        content: const Text('現在のソロプレイを終了して前の画面に戻ります。よろしいですか？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('戻る'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
