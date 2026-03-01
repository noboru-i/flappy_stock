import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../config.dart';
import '../flappy_stock.dart';
import '../flappy_world.dart';

class MinimapComponent extends PositionComponent
    with HasGameReference<FlappyStock> {
  static const _minimapWidth = 72.0;
  static const _minimapHeight = 110.0;
  static const _padding = 4.0;

  MinimapComponent()
    : super(
        position: Vector2(8, 52),
        size: Vector2(_minimapWidth, _minimapHeight),
      );

  final _bgPaint = Paint()..color = const Color(0xCC131722);
  final _borderPaint =
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
  final _bullPaint =
      Paint()
        ..color = const Color(0xFF26A69A)
        ..style = PaintingStyle.fill;
  final _bearPaint =
      Paint()
        ..color = const Color(0xFFEF5350)
        ..style = PaintingStyle.fill;
  final _wickPaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
  final _progressPaint =
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
  final _birdPaint = Paint()..color = const Color(0xFFFFFF00);

  @override
  void render(Canvas canvas) {
    if (game.playState != PlayState.playing) return;

    final world = game.world as FlappyWorld;
    final allCandles = world.allCandles;
    if (allCandles.isEmpty) return;

    final traveledX = world.traveledX;
    final birdFlameY = world.birdFlameY;

    // 背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3)),
      _bgPaint,
    );

    // 枠線
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3)),
      _borderPaint,
    );

    final contentWidth = _minimapWidth - _padding * 2;
    final contentHeight = _minimapHeight - _padding * 2;
    final maxJsonY = stageHeight / 3; // ≈ 616

    // ステージ全体スパン（最後のローソク足 spawnX + 余白）
    final totalSpan = allCandles.last.spawnX + 600.0;

    // ローソク足を描画
    for (final candle in allCandles) {
      final x = _padding + (candle.spawnX / totalSpan) * contentWidth;
      final isBull = candle.close >= candle.open;
      final bodyPaint = isBull ? _bullPaint : _bearPaint;

      // ヒゲ
      final yHigh =
          _padding + (1.0 - candle.high / maxJsonY) * contentHeight;
      final yLow =
          _padding + (1.0 - candle.low / maxJsonY) * contentHeight;
      _wickPaint.color = bodyPaint.color;
      canvas.drawLine(
        Offset(x + 1.5, yHigh),
        Offset(x + 1.5, yLow),
        _wickPaint,
      );

      // 実体
      final yOpen =
          _padding + (1.0 - candle.open / maxJsonY) * contentHeight;
      final yClose =
          _padding + (1.0 - candle.close / maxJsonY) * contentHeight;
      canvas.drawRect(
        Rect.fromLTRB(x, min(yOpen, yClose), x + 3, max(yOpen, yClose)),
        bodyPaint,
      );
    }

    // 現在進行位置の縦線
    final progressX =
        _padding + (traveledX / totalSpan).clamp(0.0, 1.0) * contentWidth;
    canvas.drawLine(
      Offset(progressX, _padding),
      Offset(progressX, _minimapHeight - _padding),
      _progressPaint,
    );

    // 鳥の現在位置（黄色い丸）
    final birdJsonY = (stageHeight - birdFlameY) / 3;
    final birdMiniY =
        _padding +
        (1.0 - (birdJsonY / maxJsonY).clamp(0.0, 1.0)) * contentHeight;
    canvas.drawCircle(Offset(progressX, birdMiniY), 2.5, _birdPaint);
  }
}
