import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

class Candle extends PositionComponent with HasGameReference<FlappyStock> {
  Candle({
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.speed,
    required this.getBirdY,
    required this.onScored,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    size: Vector2(pipeWidth, gameHeight - groundHeight),
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
  final double Function() getBirdY;

  /// 鳥が通過しスコア加算されたときに呼ばれるコールバック
  final VoidCallback onScored;

  bool _scored = false;

  static const _wickWidth = 2.0;
  static const _yangColor = Color(0xFF26A69A); // 陽線（緑）
  static const _inColor   = Color(0xFFEF5350); // 陰線（赤）

  @override
  void render(Canvas canvas) {
    final maxY = gameHeight - groundHeight;

    // JSON座標 → Flame座標変換（上端=0、下方向が正）
    final flameHigh  = maxY - high;
    final flameLow   = maxY - low;
    final flameOpen  = maxY - open;
    final flameClose = maxY - close;

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

    // 鳥の x 位置（gameWidth * 0.25）をローソク足右端が通過した瞬間にスコア加算
    if (!_scored && position.x + pipeWidth < gameWidth * 0.25) {
      _scored = true;
      final birdFlameY = getBirdY();
      final jsonY = ((gameHeight - groundHeight) - birdFlameY)
          .clamp(0.0, gameHeight - groundHeight);
      // 鳥がヒゲの範囲内（low 〜 high）を通過した場合のみスコアを加算
      if (jsonY >= low && jsonY <= high) {
        game.score.value += jsonY.round();
      }
      onScored();
    }

    // 画面左端を超えたら削除
    if (position.x < -pipeWidth * 2) removeFromParent();
  }
}
