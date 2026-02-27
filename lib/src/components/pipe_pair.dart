import 'dart:async';
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

class PipePair extends PositionComponent
    with HasGameReference<FlappyStock> {

  PipePair({
    required this.gapTop,
    required this.gapBottom,
    required this.speed,
    required this.getBirdY,
    this.bonusTop,
    this.bonusBottom,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    anchor: Anchor.topLeft,
  );

  final double gapTop;
  final double gapBottom;
  final double speed;

  /// ボーナスゾーン判定のため、現在の鳥の y 座標を返すコールバック。
  final double Function() getBirdY;

  final double? bonusTop;
  final double? bonusBottom;

  bool _scored = false;

  static const _pipeColor = Color(0xff5aad3e);

  @override
  FutureOr<void> onLoad() async {
    // 上パイプ
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(pipeWidth, gapTop),
      paint: Paint()..color = _pipeColor,
      children: [RectangleHitbox()],
    ));

    // 下パイプ
    add(RectangleComponent(
      position: Vector2(0, gapBottom),
      size: Vector2(pipeWidth, gameHeight - gapBottom),
      paint: Paint()..color = _pipeColor,
      children: [RectangleHitbox()],
    ));

    // ボーナスゾーン可視化
    if (bonusTop != null) {
      add(_BonusZoneComponent(
        position: Vector2(0, gapTop),
        size: Vector2(pipeWidth, bonusTop! - gapTop),
        topZone: true,
      ));
    }
    if (bonusBottom != null) {
      add(_BonusZoneComponent(
        position: Vector2(0, bonusBottom!),
        size: Vector2(pipeWidth, gapBottom - bonusBottom!),
        topZone: false,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    // スコア加算：鳥の位置（gameWidth * 0.25）をパイプ右端が通過した瞬間
    if (!_scored && position.x + pipeWidth < gameWidth * 0.25) {
      _scored = true;
      final birdY = getBirdY();
      game.score.value += _isInBonusZone(birdY) ? 2 : 1;
    }

    // 画面左端を超えたら削除
    if (position.x < -pipeWidth * 2) removeFromParent();
  }

  bool _isInBonusZone(double birdY) {
    if (bonusTop != null && birdY >= gapTop && birdY <= bonusTop!) return true;
    if (bonusBottom != null && birdY >= bonusBottom! && birdY <= gapBottom) return true;
    return false;
  }
}

class _BonusZoneComponent extends PositionComponent {
  _BonusZoneComponent({
    required Vector2 position,
    required Vector2 size,
    required this.topZone,
  }) : super(position: position, size: size);

  final bool topZone;
  double _elapsed = 0;

  static const _goldColor = Color(0xFFFFD700);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.45 + 0.25 * math.sin(_elapsed * 3.5);

    // パイプ側が明るく、ギャップ中央側に向かって透明になるグラデーション
    final begin = topZone ? Alignment.topCenter : Alignment.bottomCenter;
    final end = topZone ? Alignment.bottomCenter : Alignment.topCenter;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [
          _goldColor.withValues(alpha: pulse),
          _goldColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), gradientPaint);

    // エッジに光るラインを追加
    final linePaint = Paint()
      ..color = _goldColor.withValues(alpha: pulse * 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final lineY = topZone ? 0.0 : size.y;
    canvas.drawLine(Offset(0, lineY), Offset(size.x, lineY), linePaint);
  }
}
