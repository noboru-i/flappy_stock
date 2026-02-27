import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

// 衝突判定の対象として識別するためのラッパークラス
class GroundTile extends RectangleComponent {
  final List<double> _linePositions;

  GroundTile({required super.position, required super.size})
    : _linePositions = _generateLinePositions(),
      super(paint: Paint()..color = const Color(0xffd7b25e));

  static List<double> _generateLinePositions() {
    final random = Random();
    final positions = <double>[];
    var x = random.nextDouble() * 30;
    while (x < gameWidth) {
      positions.add(x);
      x += 15 + random.nextDouble() * 50;
    }
    return positions;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final linePaint = Paint()
      ..color = const Color(0xffb89040)
      ..strokeWidth = 2;
    for (final x in _linePositions) {
      canvas.drawLine(Offset(x, 4), Offset(x, size.y * 0.6), linePaint);
    }
  }

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }
}

class Ground extends PositionComponent
    with HasGameReference<FlappyStock> {

  @override
  FutureOr<void> onLoad() async {
    // 2枚並べてタイリング
    for (var i = 0; i < 2; i++) {
      add(GroundTile(
        position: Vector2(gameWidth * i, gameHeight - groundHeight),
        size: Vector2(gameWidth, groundHeight),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    for (final tile in children.query<GroundTile>()) {
      tile.position.x -= groundSpeed * dt;
      // 左端を超えたら右端へ移動（無限ループ）
      if (tile.position.x <= -gameWidth) {
        tile.position.x += gameWidth * 2;
      }
    }
  }
}
