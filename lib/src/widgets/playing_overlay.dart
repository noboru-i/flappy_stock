import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flappy_stock.dart';

class PlayingOverlay extends StatelessWidget {
  const PlayingOverlay({super.key, required this.game});

  final FlappyStock game;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HudDisplay(game: game),
        const Spacer(),
        _TradeModeButtons(game: game),
      ],
    );
  }
}

class _HudDisplay extends StatelessWidget {
  const _HudDisplay({required this.game});

  final FlappyStock game;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.pressStart2p(
      fontSize: 9,
      color: Colors.white70,
    );
    final valueStyle = GoogleFonts.pressStart2p(
      fontSize: 10,
      color: Colors.white,
    );
    final shortStyle = GoogleFonts.pressStart2p(
      fontSize: 9,
      color: const Color(0xFFFFB74D),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.black.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ValueListenableBuilder<double>(
            valueListenable: game.shares,
            builder: (context, shares, _) {
              return ValueListenableBuilder<double>(
                valueListenable: game.cash,
                builder: (context, cash, _) {
                  return ValueListenableBuilder<ShortPosition?>(
                    valueListenable: game.shortPosition,
                    builder: (context, shortPos, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('株数', style: labelStyle),
                              Text(
                                shares.toStringAsFixed(1),
                                style: valueStyle,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('現金', style: labelStyle),
                              Text(
                                '¥${cash.toStringAsFixed(0)}',
                                style: valueStyle,
                              ),
                            ],
                          ),
                          if (shortPos != null)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('空売り中', style: shortStyle),
                                Text(
                                  '100株@${shortPos.price.toStringAsFixed(0)}',
                                  style: shortStyle,
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _NewsTicker(game: game),
      ],
    );
  }
}

class _NewsTicker extends StatelessWidget {
  const _NewsTicker({required this.game});

  final FlappyStock game;

  static const _bubbleWidth = 260.0;
  static const _tailWidth = 24.0;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.pressStart2p(
      fontSize: 8,
      color: Colors.black87,
      height: 1.4,
    );

    return ValueListenableBuilder<List<NewsTickerBubble>>(
      valueListenable: game.newsTickerBubbles,
      builder: (context, bubbles, _) {
        if (bubbles.isEmpty) return const SizedBox.shrink();

        final sorted = [...bubbles]
          ..sort((a, b) => a.centerX.compareTo(b.centerX));

        return SizedBox(
          height: 74,
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (var index = 0; index < sorted.length; index++)
                      _buildBubble(bubble: sorted[index], textStyle: textStyle),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubble({
    required NewsTickerBubble bubble,
    required TextStyle textStyle,
  }) {
    final split = bubble.text.split('｜');
    final dateLabel = split.isNotEmpty ? split.first : '';
    final summary = split.length > 1 ? split.sublist(1).join('｜') : bubble.text;

    return Positioned(
      left: bubble.centerX - _bubbleWidth / 2,
      top: 0,
      width: _bubbleWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 3),
                  child: Text(
                    dateLabel,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 6,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Text(
                    summary,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: _bubbleWidth / 2 - _tailWidth / 2,
            bottom: -14,
            child: _NewsBubbleTail(),
          ),
        ],
      ),
    );
  }
}

class _NewsBubbleTail extends StatelessWidget {
  const _NewsBubbleTail();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 14),
      painter: _NewsBubbleTailPainter(),
    );
  }
}

class _NewsBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.50, size.height)
      ..close();

    final fill = Paint()..color = Colors.white.withValues(alpha: 0.72);

    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TradeModeButtons extends StatelessWidget {
  const _TradeModeButtons({required this.game});

  final FlappyStock game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TradeMode>(
      valueListenable: game.tradeMode,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: game.shares,
          builder: (context, shares, _) {
            return ValueListenableBuilder<double>(
              valueListenable: game.cash,
              builder: (context, cash, _) {
                return ValueListenableBuilder<ShortPosition?>(
                  valueListenable: game.shortPosition,
                  builder: (context, shortPos, _) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: '現物買い\n(A)',
                              mode: TradeMode.buy,
                              currentMode: currentMode,
                              // 現金がないと買えない
                              isDisabled: cash <= 0,
                              game: game,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ModeButton(
                              label: '現物売り\n(S)',
                              mode: TradeMode.sell,
                              currentMode: currentMode,
                              // 保有株がないと売れない
                              isDisabled: shares <= 0,
                              game: game,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _ModeButton(
                              label: '空売り\n(D)',
                              mode: TradeMode.short,
                              currentMode: currentMode,
                              // 既に空売りポジションがあると新規不可
                              isDisabled: shortPos != null,
                              game: game,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.mode,
    required this.currentMode,
    required this.isDisabled,
    required this.game,
  });

  final String label;
  final TradeMode mode;
  final TradeMode currentMode;
  final bool isDisabled;
  final FlappyStock game;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;

    final bgColor = isDisabled
        ? const Color(0xFF1A1A24)
        : isSelected
        ? const Color(0xFF26A69A)
        : const Color(0xFF2A2A3A);
    final borderColor = isDisabled
        ? const Color(0xFF333340)
        : isSelected
        ? const Color(0xFF26A69A)
        : const Color(0xFF555570);
    final textColor = isDisabled
        ? Colors.white24
        : isSelected
        ? Colors.white
        : Colors.white54;

    return GestureDetector(
      onTapDown: isDisabled
          ? null
          : (_) {
              game.tradeMode.value = mode;
              game.flapStart();
            },
      onTapUp: isDisabled ? null : (_) => game.flapEnd(),
      onTapCancel: isDisabled ? null : () => game.flapEnd(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.pressStart2p(fontSize: 9, color: textColor),
        ),
      ),
    );
  }
}
