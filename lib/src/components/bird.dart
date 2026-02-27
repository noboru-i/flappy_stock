import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';
import 'pipe_pair.dart';

class Bird extends CircleComponent
    with CollisionCallbacks, HasGameReference<FlappyStock> {

  Bird({required super.position})
    : super(
        radius: birdRadius,
        anchor: Anchor.center,
        paint: Paint()
          ..color = const Color(0xffFFD700)
          ..style = PaintingStyle.fill,
        children: [CircleHitbox(radius: 1)],
      );

  final Vector2 _velocity = Vector2.zero();
  bool _isFlapHeld = false;
  double _flapHoldTime = 0;

  void flapStart() {
    _isFlapHeld = true;
    _flapHoldTime = 0;
  }

  void flapEnd() {
    _isFlapHeld = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    if (_isFlapHeld) {
      _flapHoldTime = (_flapHoldTime + dt).clamp(0.0, maxFlapHoldTime);
      final t = _flapHoldTime / maxFlapHoldTime;
      // 押し時間の二乗に比例して上昇加速度が増大
      final lift = flapLiftBase + flapLiftExtra * t * t;
      _velocity.y -= lift * dt;
    }

    _velocity.y += gravity * dt;
    position += _velocity * dt;

    // 傾き演出（速度に比例して回転）
    angle = (_velocity.y * 0.002).clamp(-0.5, 1.2);

    // 天井に当たったら停止
    if (position.y - radius <= 0) {
      _velocity.y = 0;
      position.y = radius;
    }

    // 地面に当たったら停止
    final groundTop = gameHeight - groundHeight;
    if (position.y + radius >= groundTop) {
      _velocity.y = 0;
      position.y = groundTop - radius;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // PipePair の子 RectangleComponent と衝突したとき
    if (other.parent is PipePair) {
      add(RemoveEffect(
        delay: 0.3,
        onComplete: () => game.playState = PlayState.gameOver,
      ));
    }
  }
}
