import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';

// 画像アセットが未用意の場合はグラデーション矩形で代替
class Background extends RectangleComponent {
  Background()
    : super(
        position: Vector2.zero(),
        size: Vector2(gameWidth, gameHeight),
        paint: Paint()..color = const Color(0xff87CEEB),
      );

  // 画像アセット使用時は ParallaxComponent に差し替え:
  //
  // class Background extends ParallaxComponent<FlappyStock> {
  //   @override
  //   FutureOr<void> onLoad() async {
  //     parallax = await game.loadParallax(
  //       [ParallaxImageData('bg_sky.png'), ParallaxImageData('bg_clouds.png')],
  //       baseVelocity: Vector2(20, 0),
  //       velocityMultiplierDelta: Vector2(1.8, 0),
  //     );
  //   }
  // }
}
