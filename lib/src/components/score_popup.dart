import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';

class ScorePopup extends TextComponent {
  ScorePopup({required String text, required Vector2 position})
    : _basePosition = position.clone(),
      super(
        text: text,
        position: position + Vector2(0, -birdRadius * 1.8),
        anchor: Anchor.center,
        priority: 100,
      );

  final Vector2 _basePosition;

  double _elapsed = 0;

  static const _duration = 0.65;
  static const _riseDistance = 70.0;

  @override
  Future<void> onLoad() async {
    _applyStyle(alpha: 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsed += dt;
    final t = (_elapsed / _duration).clamp(0.0, 1.0);

    position =
        _basePosition + Vector2(0, -birdRadius * 1.8 - _riseDistance * t);
    _applyStyle(alpha: 1.0 - t);

    if (t >= 1.0) {
      removeFromParent();
    }
  }

  void _applyStyle({required double alpha}) {
    textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFFFD54F).withValues(alpha: alpha),
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
