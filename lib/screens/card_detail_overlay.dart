import 'package:flutter/material.dart';

import '../models/card_data.dart';
import '../widgets/card_tile.dart';

class CardDetailOverlay extends StatefulWidget {
  const CardDetailOverlay({
    super.key,
    required this.initialIndex,
    required this.cards,
  });

  final int initialIndex;
  final List<CardData> cards;

  @override
  State<CardDetailOverlay> createState() => _CardDetailOverlayState();
}

class _CardDetailOverlayState extends State<CardDetailOverlay>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  );

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController.forward();
    _pageController.addListener(() {
      final page = _pageController.page?.round();
      if (page != null && page != _currentIndex) {
        setState(() {
          _currentIndex = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigate(int delta) {
    final next = (_currentIndex + delta).clamp(0, widget.cards.length - 1);
    if (next != _currentIndex) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(color: Colors.black54),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Material(
                      color: theme.colorScheme.surface,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.cards.length,
                            itemBuilder: (context, index) {
                              final card = widget.cards[index];
                              return _CardDetailPage(
                                card: card,
                                heroTag: 'card-${card.id}-$index',
                              );
                            },
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              color: theme.colorScheme.onSurface,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          if (widget.cards.length > 1)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                iconSize: 32,
                                color: theme.colorScheme.onSurface,
                                onPressed: () => _navigate(-1),
                                icon: const Icon(Icons.chevron_left),
                              ),
                            ),
                          if (widget.cards.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                iconSize: 32,
                                color: theme.colorScheme.onSurface,
                                onPressed: () => _navigate(1),
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _PageIndicator(
                    key: ValueKey(_currentIndex),
                    currentIndex: _currentIndex,
                    length: widget.cards.length,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDetailPage extends StatelessWidget {
  const _CardDetailPage({required this.card, required this.heroTag});

  final CardData card;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: heroTag,
            child: CardTile(card: card),
          ),
          const SizedBox(height: 24),
          Text(
            card.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _InfoChip(label: card.color, icon: Icons.palette_outlined),
              _InfoChip(label: card.type, icon: Icons.aspect_ratio),
              _InfoChip(label: card.rarity, icon: Icons.star_border),
              if (card.cost != null)
                _InfoChip(
                  label: 'Cost ${card.cost}',
                  icon: Icons.savings_outlined,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailStatList(card: card),
          if (card.attribute != null && card.attribute!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('属性', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(card.attribute!, style: theme.textTheme.bodyMedium),
          ],
          if (card.feature != null && card.feature!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('効果', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(card.feature!, style: theme.textTheme.bodyMedium),
          ],
          if (card.illustrator != null && card.illustrator!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Illustration: ${card.illustrator}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
      shape: const StadiumBorder(),
    );
  }
}

class _DetailStatList extends StatelessWidget {
  const _DetailStatList({required this.card});

  final CardData card;

  @override
  Widget build(BuildContext context) {
    final stats = <_StatEntry>[];
    if (card.ap != null) {
      stats.add(_StatEntry('AP', card.ap.toString()));
    }
    if (card.hp != null) {
      stats.add(_StatEntry('HP', card.hp.toString()));
    }
    if (card.apCorrection != null && card.apCorrection!.isNotEmpty) {
      stats.add(_StatEntry('AP修正', card.apCorrection!));
    }
    if (card.hpCorrection != null && card.hpCorrection!.isNotEmpty) {
      stats.add(_StatEntry('HP修正', card.hpCorrection!));
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: stats
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    entry.value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatEntry {
  const _StatEntry(this.label, this.value);

  final String label;
  final String value;
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    super.key,
    required this.currentIndex,
    required this.length,
  });

  final int currentIndex;
  final int length;

  @override
  Widget build(BuildContext context) {
    if (length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        '${currentIndex + 1} / $length',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
