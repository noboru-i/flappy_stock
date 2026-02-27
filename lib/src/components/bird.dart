import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';
import 'pipe_pair.dart';
import 'ground.dart';

class Bird extends CircleComponent
    with CollisionCallbacks, HasGameReference<FlappyStock> {

  Bird({required super.position})
    : super(
        radius: birdRadius,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xffFFD700)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox()],
      );

  final Vector2 _velocity = Vector2.zero();

  void flap() => _velocity.y = flapImpulse;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    _velocity.y += gravity * dt;
    position += _velocity * dt;

    // 傾き演出（速度に比例して回転）
    angle = (_velocity.y * 0.002).clamp(-0.5, 1.2);

    // 天井に当たったら跳ね返し
    if (position.y - radius <= 0) {
      _velocity.y = 0;
      position.y = radius;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // PipePair の子 RectangleComponent か GroundTile と衝突したとき
    if (other.parent is PipePair || other is GroundTile) {
      add(RemoveEffect(
        delay: 0.3,
        onComplete: () => game.playState = PlayState.gameOver,
      ));
    }
  }
}
