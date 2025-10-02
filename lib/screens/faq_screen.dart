import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<FaqItem> _generalRules = [];
  List<FaqItem> _individualCards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFaqData();
  }

  Future<void> _loadFaqData() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 60),
        ),
      );
      await remoteConfig.setDefaults(const {
        'faq_general_rules': '[]',
        'faq_individual_cards': '[]',
      });
      await remoteConfig.fetchAndActivate();

      final generalRulesJson = remoteConfig.getString('faq_general_rules');
      final individualCardsJson = remoteConfig.getString(
        'faq_individual_cards',
      );

      final List<dynamic> generalRulesData = json.decode(generalRulesJson);
      final List<dynamic> individualCardsData = json.decode(
        individualCardsJson,
      );

      setState(() {
        _generalRules = generalRulesData
            .map((item) => FaqItem.fromJson(item))
            .toList();
        _individualCards = individualCardsData
            .map((item) => FaqItem.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'FAQデータの読み込みに失敗しました';
        _isLoading = false;
      });
      debugPrint('FAQ load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF3E3E3E),
      appBar: CupertinoNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: CupertinoNavigationBarBackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        middle: const Text(
          'よくある質問',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _loadFaqData();
                        },
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                ),
              )
            : CupertinoTabScaffold(
                tabBar: CupertinoTabBar(
                  backgroundColor: theme.colorScheme.primary,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.6),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.rule),
                      label: '汎用ルール',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.style),
                      label: 'カード個別',
                    ),
                  ],
                ),
                tabBuilder: (context, index) {
                  return CupertinoTabView(
                    builder: (context) {
                      return Container(
                        color: const Color(0xFF3E3E3E),
                        child: _buildFaqList(
                          index == 0 ? _generalRules : _individualCards,
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFaqList(List<FaqItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'FAQはまだありません',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _FaqCard(item: items[index]);
      },
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.item});

  final FaqItem item;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.item.section.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[700]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.blue[400]!.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.item.section,
                      style: TextStyle(
                        color: Colors.blue[200],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.yellow[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.item.question,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[400],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.item.answer,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.item.updated.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.update,
                                size: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '更新: ${widget.item.updated}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FaqItem {
  final String section;
  final String question;
  final String answer;
  final String updated;

  FaqItem({
    required this.section,
    required this.question,
    required this.answer,
    required this.updated,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      section: json['section'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      updated: json['updated'] as String? ?? '',
    );
  }
}
