import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/models/deck.dart';
import 'package:senkai_sengi/utils/master.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';

class SoloPlayScreen extends StatefulWidget {
  const SoloPlayScreen({super.key, required this.deck});

  final Deck deck;

  @override
  State<SoloPlayScreen> createState() => _SoloPlayScreenState();
}

class _SoloPlayScreenState extends State<SoloPlayScreen> {
  // ゲームエリア
  List<CardData> _library = [];
  List<CardData> _hand = [];
  List<CardData> _field = [];
  List<CardData> _graveyard = [];
  List<CardData> _magicDeck = [];
  List<CardData> _wallZone = []; // ウォールゾーンのカード

  // ゲーム状態
  bool _isGameStarted = false;
  int _turnCount = 0;
  bool _isFirstPlayer = true; // true: 先攻, false: 後攻

  List<CardData> _magicZone = []; // 魔力ゾーンのカード

  @override
  void initState() {
    super.initState();
    _initializeGame();
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
      _field = [];
      _graveyard = [];
      _wallZone = [];
      _magicZone = [];
      _isGameStarted = false;
      _turnCount = 0;
    });
  }

  void _startGame() {
    setState(() {
      _shuffleDeck();
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
  }

  void _shuffleDeck() {
    final random = Random();
    _library.shuffle(random);
  }

  void _drawCards(int count) {
    for (int i = 0; i < count && _library.isNotEmpty; i++) {
      setState(() {
        _hand.add(_library.removeAt(0));
      });
    }
  }

  void _playCard(int handIndex) {
    if (handIndex < _hand.length) {
      setState(() {
        final card = _hand.removeAt(handIndex);
        _field.add(card);
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

  void _moveFieldToGraveyard(int fieldIndex) {
    if (fieldIndex < _field.length) {
      setState(() {
        final card = _field.removeAt(fieldIndex);
        _graveyard.add(card);
      });
    }
  }

  void _reshuffleGraveyard() {
    setState(() {
      _library.addAll(_graveyard);
      _graveyard.clear();
      _shuffleDeck();
    });
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
    // 実装：すべてのカードをアップ状態にする（ここでは状態管理のみ）
  }

  void _drawPhase() {
    // 2.ドローフェーズ：メインデッキの上から一枚引く
    _drawCards(1);
  }

  void _setPhase() {
    // 3.セットフェーズ：魔力デッキの上から魔力を2つ（先攻１ターン目は1つ）、アップで魔力ゾーンに置く
    int magicCards = (_isFirstPlayer && _turnCount == 1) ? 1 : 2;
    for (int i = 0; i < magicCards && _magicDeck.isNotEmpty; i++) {
      _magicZone.add(_magicDeck.removeAt(0));
    }
  }

  void _endPhase() {
    // エンドフェーズの処理（必要に応じて）
  }

  void _useMagicCard(int index) {
    if (index < _magicZone.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('魔力カード使用'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('カード: ${_magicZone[index].name}'),
              const SizedBox(height: 8),
              const Text('どうしますか？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _graveyard.add(_magicZone.removeAt(index));
                });
                Navigator.of(context).pop();
              },
              child: const Text('捨て札に送る'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _hand.add(_magicZone.removeAt(index));
                });
                Navigator.of(context).pop();
              },
              child: const Text('手札に戻す'),
            ),
          ],
        ),
      );
    }
  }

  void _resetGame() {
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF3E3E3E),
        appBar: CupertinoNavigationBar(
          backgroundColor: theme.colorScheme.primary,
          leading: CupertinoNavigationBarBackButton(
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
          middle: Text(
            'ソロプレイ - ${widget.deck.name}',
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
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('リセット'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetGame();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: _isGameStarted ? _buildGameArea() : _buildStartScreen(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Stack(
      children: [
        // プレイマット背景
        Center(
          child: Image.asset(
            'assets/images/playmat_black.png',
            fit: BoxFit.contain,
          ),
        ),
        // スタート画面コンテンツ
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
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
                              children: const [
                                Text('先攻'),
                                Text('初期手札4枚', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            selected: _isFirstPlayer,
                            onSelected: (selected) {
                              setState(() {
                                _isFirstPlayer = true;
                              });
                            },
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: _isFirstPlayer
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('後攻'),
                                Text('初期手札4枚', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            selected: !_isFirstPlayer,
                            onSelected: (selected) {
                              setState(() {
                                _isFirstPlayer = false;
                              });
                            },
                            selectedColor: Colors.red,
                            labelStyle: TextStyle(
                              color: !_isFirstPlayer
                                  ? Colors.white
                                  : Colors.white70,
                            ),
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
        ),
      ],
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
                                height: playmatConstraints.maxHeight * 0.35,
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
                                child: _buildGraveyard(),
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

  Widget _buildLibraryAndGraveyard() {
    return Row(
      children: [
        // ライブラリ
        Expanded(
          child: GestureDetector(
            onTap: () => _drawCards(1),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, color: Colors.blue, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'ライブラリ',
                    style: TextStyle(color: Colors.blue[200], fontSize: 14),
                  ),
                  Text(
                    '${_library.length}枚',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'タップでドロー',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 墓地
        Expanded(
          child: GestureDetector(
            onLongPress: _graveyard.isNotEmpty ? _reshuffleGraveyard : null,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '墓地',
                    style: TextStyle(color: Colors.red[200], fontSize: 14),
                  ),
                  Text(
                    '${_graveyard.length}枚',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_graveyard.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '長押しでシャッフル',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.8), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.landscape, color: Colors.green[300], size: 20),
              const SizedBox(width: 8),
              Text(
                '場 (${_field.length}枚)',
                style: TextStyle(color: Colors.green[300], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _field.isEmpty
                ? Center(
                    child: Text(
                      'カードがありません',
                      style: TextStyle(color: Colors.green[200]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _field.length,
                    itemBuilder: (context, index) {
                      final card = _field[index];
                      return GestureDetector(
                        onTap: () => _moveFieldToGraveyard(index),
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 4),
                          child: Stack(
                            children: [
                              CardTile(card: card),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildHand() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.8), width: 1),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(
            height: 120,
            child: _hand.isEmpty
                ? Center(
                    child: Text(
                      'カードがありません',
                      style: TextStyle(color: Colors.orange[200]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _hand.length,
                    itemBuilder: (context, index) {
                      final card = _hand[index];
                      return GestureDetector(
                        onTap: () => _playCard(index),
                        onLongPress: () => _discardCard(index),
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 4),
                          child: Stack(
                            children: [
                              CardTile(card: card),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: const Text(
                                    'タップ:場\n長押し:捨て',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
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

  // 上部レーン（3つの攻撃ゾーン）
  Widget _buildLanes(BoxConstraints playmatConstraints) {
    return Row(
      children: List.generate(3, (index) {
        final laneCards = _field
            .where((card) => _field.indexOf(card) % 3 == index)
            .toList();
        return Expanded(
          child: laneCards.isEmpty
              ? const Center(
                  child: Text(
                    '空',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  itemCount: laneCards.length,
                  itemBuilder: (context, cardIndex) {
                    return SizedBox(
                      height: playmatConstraints.maxWidth * 0.2,
                      child: CardTile(card: laneCards[cardIndex]),
                    );
                  },
                ),
        );
      }),
    );
  }

  // ウォールゾーン - 重なり表示
  Widget _buildWallZone(BoxConstraints playmatConstraints) {
    return _wallZone.isEmpty
        ? Center(
            child: Text(
              '空',
              style: TextStyle(color: Colors.blue[200], fontSize: 12),
            ),
          )
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
              onTap: () => _flipWallCard(index),
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

  void _flipWallCard(int index) {
    if (index < _wallZone.length) {
      // ウォールカードをタップした時の処理（例：手札に移動）
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ウォールカード'),
          content: Text('カード: ${_wallZone[index].name}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _hand.add(_wallZone.removeAt(index));
                });
                Navigator.of(context).pop();
              },
              child: const Text('手札に移動'),
            ),
          ],
        ),
      );
    }
  }

  // 魔力デッキ
  Widget _buildMagicDeck(BoxConstraints playmatConstraints) {
    double cardHeight = playmatConstraints.maxWidth * 0.2;
    return GestureDetector(
      onTap: () {
        // 魔力デッキから1枚ドロー
        if (_magicDeck.isNotEmpty) {
          setState(() {
            _hand.add(_magicDeck.removeAt(0));
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: _magicDeck.isEmpty
            ? AspectRatio(
                aspectRatio: 670 / 950,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: const Text(
                      '空',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(cardHeight / 1407 * 30),
                child: AspectRatio(
                  aspectRatio: 670 / 950,
                  child: Image.asset(
                    'assets/images/power_card_back.png',
                    fit: BoxFit.cover,
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
      onTap: () => _drawCards(1),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: _library.isEmpty
            ? AspectRatio(
                aspectRatio: 670 / 950,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: const Text(
                      '空',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                ),
              )
            : ClipRRect(
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
    );
  }

  // 魔力ゾーン（プレイマット上の表示）
  Widget _buildMagicZoneIndicator() {
    return Center(
      child: Column(
        children: [
          Expanded(
            child: _magicZone.isEmpty
                ? Center(
                    child: Text(
                      '空',
                      style: TextStyle(color: Colors.purple[200], fontSize: 12),
                    ),
                  )
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
                        onTap: () => _useMagicCard(index),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.purple.withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          child: CardTile(card: card),
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
                        onLongPress: () => _discardCard(index),
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Expanded(child: CardTile(card: card)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: const Text(
                                  'タップ:場 | 長押し:捨て',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
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

  // 旧魔力ゾーン（使用しない）
  Widget _buildMagicZone() {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          const Text(
            '魔力ゾーン（手札）',
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
          Expanded(
            child: _hand.isEmpty
                ? const Center(
                    child: Text(
                      'カードがありません',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 670 / 950,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemCount: _hand.length,
                    itemBuilder: (context, index) {
                      final card = _hand[index];
                      return GestureDetector(
                        onTap: () => _playCard(index),
                        onLongPress: () => _discardCard(index),
                        child: CardTile(card: card),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 捨て札
  Widget _buildGraveyard() {
    return GestureDetector(
      onLongPress: _graveyard.isNotEmpty ? _reshuffleGraveyard : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete, color: Colors.red, size: 30),
            const SizedBox(height: 4),
            const Text(
              '捨て札',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            Text(
              '${_graveyard.length}枚',
              style: TextStyle(color: Colors.red[300], fontSize: 18),
            ),
            if (_graveyard.isNotEmpty)
              const Text(
                '長押しでシャッフル',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
          ],
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
            onPressed: _library.isNotEmpty ? () => _drawCards(1) : null,
            icon: const Icon(Icons.add_box, size: 16),
            label: const Text('ドロー', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _nextPhase,
            icon: const Icon(Icons.skip_next, size: 16),
            label: Text('ターン終了',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _shuffleDeck,
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('シャッフル', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
