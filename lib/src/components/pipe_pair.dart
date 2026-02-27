import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';
import '../data/pipe_data.dart';

class PipePair extends PositionComponent
    with HasGameReference<FlappyStock> {

  PipePair({
    required this.gapTop,
    required this.gapBottom,
    required this.speed,
    required this.getBirdY,
    this.bonusZoneTop,
    this.bonusZoneBottom,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    anchor: Anchor.topLeft,
  );

  final double gapTop;
  final double gapBottom;
  final double speed;

  /// ボーナスゾーン判定のため、現在の鳥の y 座標を返すコールバック。
  final double Function() getBirdY;

  final BonusZone? bonusZoneTop;
  final BonusZone? bonusZoneBottom;

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
    if (bonusZoneTop != null &&
        birdY >= bonusZoneTop!.start &&
        birdY <= bonusZoneTop!.end) {
      return true;
    }
    if (bonusZoneBottom != null &&
        birdY >= bonusZoneBottom!.start &&
        birdY <= bonusZoneBottom!.end) {
      return true;
    }
    return false;
  }
}
