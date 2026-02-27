import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import '../config.dart';

// 衝突判定の対象として識別するためのラッパークラス
class GroundTile extends RectangleComponent {
  GroundTile({required super.position, required super.size})
    : super(paint: Paint()..color = const Color(0xffd7b25e));

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
