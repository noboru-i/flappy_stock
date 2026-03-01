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

    return Container(
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
    );
  }
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
                              label: '現物買い',
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
                              label: '現物売り',
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
                              label: '空売り',
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
