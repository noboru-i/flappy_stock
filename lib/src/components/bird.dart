import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../flappy_stock.dart';
import '../config.dart';

class Bird extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlappyStock> {

  late SpriteComponent _spriteComponent;
  late Sprite _spriteUp;
  late Sprite _spriteDown;

  Bird({required super.position})
    : super(
        size: Vector2.all(birdRadius * 2),
        anchor: Anchor.center,
      );

  final Vector2 _velocity = Vector2.zero();
  bool _isFlapHeld = false;
  double _flapHoldTime = 0;

  @override
  Future<void> onLoad() async {
    _spriteUp = await game.loadSprite('bird_up.png');
    _spriteDown = await game.loadSprite('bird_down.png');

    _spriteComponent = SpriteComponent(
      sprite: _spriteDown,
      size: size.clone(),
    );
    add(_spriteComponent);
    add(CircleHitbox(radius: 1));
  }

  void flapStart() {
    _isFlapHeld = true;
    _flapHoldTime = 0;
    _spriteComponent.sprite = _spriteUp;
  }

  void flapEnd() {
    _isFlapHeld = false;
    _spriteComponent.sprite = _spriteDown;
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
    _spriteComponent.angle = (_velocity.y * 0.002).clamp(-0.5, 1.2);

    // 天井に当たったら停止
    if (position.y - birdRadius <= 0) {
      _velocity.y = 0;
      position.y = birdRadius;
    }

    // 地面に当たったら停止
    if (position.y + birdRadius >= stageHeight) {
      _velocity.y = 0;
      position.y = stageHeight - birdRadius;
    }
  }
}
