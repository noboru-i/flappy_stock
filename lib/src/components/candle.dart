import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

typedef CandleScoredCallback = void Function(
  double jsonY,
  double high,
  double low,
  double close,
  bool isLast,
);

class Candle extends PositionComponent with HasGameReference<FlappyStock> {
  Candle({
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.speed,
    required this.isLast,
    required this.getBirdY,
    required this.onScored,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    size: Vector2(pipeWidth, stageHeight),
    anchor: Anchor.topLeft,
  );

  /// ヒゲ上端（JSON座標：画面下端=0）
  final double high;

  /// ヒゲ下端（JSON座標：画面下端=0）
  final double low;

  /// 始値（JSON座標）
  final double open;

  /// 終値（JSON座標）
  final double close;

  final double speed;

  /// このローソク足がステージ最後のものか
  final bool isLast;

  final double Function() getBirdY;

  /// 鳥が通過したときに呼ばれるコールバック
  final CandleScoredCallback onScored;

  bool _scored = false;

  static const _wickWidth = 2.0;
  static const _yangColor = Color(0xFF26A69A); // 陽線（緑）
  static const _inColor   = Color(0xFFEF5350); // 陰線（赤）

  @override
  void render(Canvas canvas) {
    // JSON座標 → Flame座標変換（yMin〜yMax の範囲をステージ全体にマッピング）
    final yMin   = game.stageYMin;
    final yRange = game.stageYMax - yMin;
    final flameHigh  = stageHeight * (1 - (high  - yMin) / yRange);
    final flameLow   = stageHeight * (1 - (low   - yMin) / yRange);
    final flameOpen  = stageHeight * (1 - (open  - yMin) / yRange);
    final flameClose = stageHeight * (1 - (close - yMin) / yRange);

    final bodyTop    = math.min(flameOpen, flameClose);
    final bodyBottom = math.max(flameOpen, flameClose);

    final isYang     = close >= open;
    final paint      = Paint()..color = isYang ? _yangColor : _inColor;

    final centerX = pipeWidth / 2;

    // ヒゲ（細い縦線）
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - _wickWidth / 2,
        flameHigh,
        _wickWidth,
        flameLow - flameHigh,
      ),
      paint,
    );

    // 実体（太い四角形）
    canvas.drawRect(
      Rect.fromLTWH(0, bodyTop, pipeWidth, bodyBottom - bodyTop),
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    position.x -= speed * dt;

    // 鳥の x 位置（gameWidth * 0.25）をローソク足右端が通過した瞬間に判定
    if (!_scored && position.x + pipeWidth < gameWidth * 0.25) {
      _scored = true;
      final birdFlameY = getBirdY();
      final yMin   = game.stageYMin;
      final yRange = game.stageYMax - yMin;
      final jsonY  = (yMin + (1 - birdFlameY / stageHeight) * yRange)
          .clamp(yMin, game.stageYMax);
      onScored(jsonY, high, low, close, isLast);
    }

    // 画面左端を超えたら削除
    if (position.x < -pipeWidth * 2) removeFromParent();
  }
}
