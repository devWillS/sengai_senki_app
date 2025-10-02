import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/card_data.dart';
import 'package:senkai_sengi/utils/color_manager.dart';
import 'package:senkai_sengi/widgets/card_tile.dart';

class HoloCard extends StatefulWidget {
  final CardData card;
  final bool showGlitter;
  final bool showHolo;
  final bool showRainbow;
  final bool showShadow;
  final bool showGloss;

  const HoloCard({
    super.key,
    required this.card,
    this.showGlitter = false,
    this.showHolo = false,
    this.showRainbow = false,
    this.showShadow = false,
    this.showGloss = false,
  });

  @override
  State<HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<HoloCard> {
  double angle = 35;
  double _rotationX = 0;
  double _rotationY = 0;
  double _rotationZ = 0;
  Offset? _startPosition;

  void _onPanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_startPosition == null) return;
    setState(() {
      final screenSize = MediaQuery.of(context).size;
      final centerX = screenSize.width / 2;
      final centerY = screenSize.height / 2;

      final dx = details.globalPosition.dx - _startPosition!.dx;
      final dy = details.globalPosition.dy - _startPosition!.dy;

      _rotationY = (-dx / centerX * angle).clamp(-angle, angle);
      _rotationX = (dy / centerY * angle).clamp(-angle, angle);
      _rotationZ = (dx * dy / (centerX * centerY) * 20).clamp(-20, 20);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _startPosition = null;
    setState(() {
      _rotationX = 0;
      _rotationY = 0;
      _rotationZ = 0;
    });
  }

  Widget _buildGlossEffect(double long) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
          gradient: LinearGradient(
            begin: Alignment(
              -0.2 - (_rotationY / angle),
              -0.2 - (_rotationX / angle),
            ),
            end: Alignment(
              0.2 - (_rotationY / angle),
              0.2 - (_rotationX / angle),
            ),
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(
                alpha: ((_rotationY.abs() + _rotationX.abs()) / 70) * 0.7,
              ),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.2, 0.5, 0.8],
          ),
        ),
      ),
    );
  }

  Widget _buildPlasticGlossEffect(double long) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
          gradient: LinearGradient(
            begin: Alignment(
              -1.0 - (_rotationY / angle),
              -1.0 - (_rotationX / angle),
            ),
            end: Alignment(
              1.0 - (_rotationY / angle),
              1.0 - (_rotationX / angle),
            ),
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(
                alpha: ((_rotationY.abs() + _rotationX.abs()) / 70) * 0.3,
              ),
              Colors.white.withValues(
                alpha: ((_rotationY.abs() + _rotationX.abs()) / 70) * 0.6,
              ),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.3, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHighlight(double long) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(
            alpha: ((_rotationY.abs() + _rotationX.abs()) / 70) * 0.5,
          ),
          width: 1,
        ),
        borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
        gradient: RadialGradient(
          center: Alignment((_rotationY / 35), (_rotationX / 35)),
          focal: Alignment((_rotationY / 70), (_rotationX / 70)),
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(
              alpha: ((_rotationY.abs() + _rotationX.abs()) / 70) * 0.2,
            ),
          ],
          stops: const [0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildGlitterEffect(double long) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
      child: Opacity(
        opacity: 0.3 * ((_rotationY.abs() + _rotationX.abs()) / 70),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(
              -1 + (_rotationY / angle),
              -1 + (_rotationX / angle),
            ),
            end: Alignment(1 + (_rotationY / angle), 1 + (_rotationX / angle)),
          ).createShader(bounds),
          blendMode: BlendMode.overlay,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.plus,
            child: Image.asset(
              'assets/images/sparkles.gif',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoloEffect() {
    return Opacity(
      opacity: 0.7 * ((_rotationY.abs() + _rotationX.abs()) / 70),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.7),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(
            -1 + (_rotationY / angle),
            -1 + (_rotationX / angle),
          ),
          end: Alignment(1 + (_rotationY / angle), 1 + (_rotationX / angle)),
        ).createShader(bounds),
        blendMode: BlendMode.screen,
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.overlay,
          child: Image.asset(
            'assets/images/holo.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withValues(alpha: 0.7),
            colorBlendMode: BlendMode.hardLight,
          ),
        ),
      ),
    );
  }

  Widget _buildRainbowEffect(double long) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(long / 950 * 23)),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            const Color(0xFFff0084).withValues(
              alpha: 0.35 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
            const Color(0xFFfca400).withValues(
              alpha: 0.3 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
            const Color(0xFFffff00).withValues(
              alpha: 0.25 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
            const Color(0xFF00ff8a).withValues(
              alpha: 0.25 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
            const Color(0xFF00cfff).withValues(
              alpha: 0.3 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
            const Color(0xFFcc4cfa).withValues(
              alpha: 0.35 * ((_rotationY.abs() + _rotationX.abs()) / 70),
            ),
          ],
          begin: Alignment(
            -1.2 + (_rotationY / angle),
            -1.2 + (_rotationX / angle),
          ),
          end: Alignment(
            1.2 + (_rotationY / angle),
            1.2 + (_rotationX / angle),
          ),
        ).createShader(bounds),
        blendMode: BlendMode.overlay,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment((_rotationY / angle), (_rotationX / angle)),
              focal: Alignment((_rotationY / 70), (_rotationX / 70)),
              colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
              stops: const [0.0, 0.9],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_rotationX * math.pi / 180)
          ..rotateY(_rotationY * math.pi / 180)
          ..rotateZ(_rotationZ * math.pi / 180),
        alignment: Alignment.center,
        child: Center(
          child: AspectRatio(
            aspectRatio: 670 / 950,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double long = max<double>(
                  constraints.maxHeight,
                  constraints.maxWidth,
                );
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(long / 950 * 23),
                    ),
                    boxShadow: widget.showShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: -5,
                              offset: const Offset(0, 0),
                            ),
                            BoxShadow(
                              color: Color.lerp(
                                const Color(0xFFffaacc),
                                const Color(0xFFddccaa),
                                0.5,
                              )!.withValues(alpha: 0.3),
                              blurRadius: 45,
                              spreadRadius: -8,
                              offset: const Offset(0, 0),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFffaacc,
                              ).withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: -5,
                              offset: const Offset(-15, -15),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFddccaa,
                              ).withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: -5,
                              offset: const Offset(15, 15),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: -10,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(long / 950 * 23),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: HexColor.from("D9D9D9"),
                              offset: Offset(_rotationY / 40, -_rotationX / 40),
                            ),
                          ],
                        ),
                        child: CardTile(card: widget.card),
                      ),
                      if (widget.showGloss) ...[
                        _buildGlossEffect(long),
                        _buildPlasticGlossEffect(long),
                      ],
                      _buildEdgeHighlight(long),
                      if (widget.showGlitter) _buildGlitterEffect(long),
                      if (widget.showHolo) _buildHoloEffect(),
                      if (widget.showRainbow) _buildRainbowEffect(long),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
