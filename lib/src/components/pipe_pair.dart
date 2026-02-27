import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

class PipePair extends PositionComponent
    with HasGameReference<FlappyStock> {

  PipePair({
    required this.gapCenterY,
    required this.speed,
  }) : super(
    position: Vector2(gameWidth + pipeWidth, 0),
    anchor: Anchor.topLeft,
  );

  final double gapCenterY;
  final double speed;
  bool _scored = false;

  static const _pipeColor = Color(0xff5aad3e);

  @override
  FutureOr<void> onLoad() async {
    // 上パイプ
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(pipeWidth, gapCenterY - pipeGap / 2),
      paint: Paint()..color = _pipeColor,
      children: [RectangleHitbox()],
    ));

    // 下パイプ
    final bottomY = gapCenterY + pipeGap / 2;
    add(RectangleComponent(
      position: Vector2(0, bottomY),
      size: Vector2(pipeWidth, gameHeight - bottomY),
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
      game.score.value++;
    }

    // 画面左端を超えたら削除
    if (position.x < -pipeWidth * 2) removeFromParent();
  }
}
