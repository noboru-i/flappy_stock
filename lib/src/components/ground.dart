import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

// 衝突判定の対象として識別するためのラッパークラス
class GroundTile extends RectangleComponent {
  GroundTile({required super.position, required super.size})
    : super(paint: Paint()..color = const Color(0xFF0F1020));

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // X軸ライン（チャートの軸）
    final linePaint = Paint()
      ..color = const Color(0xFF252540)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, 0), Offset(size.x, 0), linePaint);
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
        position: Vector2(gameWidth * i, stageHeight),
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
