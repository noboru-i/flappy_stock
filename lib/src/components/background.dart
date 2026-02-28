import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../flappy_stock.dart';

class Background extends PositionComponent with HasGameReference<FlappyStock> {
  static const _bgColor = Color(0xFF131722);
  static const _gridColor = Color(0xFF252540);
  static const _labelColor = Color(0xFF787B9E);

  // Y軸グリッド間隔（JSON Y座標単位：画面下端=0）
  static const _gridIntervalJson = 50.0;
  // X軸グリッド間隔（Flame X座標単位：ゲーム幅 400px を 5 分割）
  static const _gridIntervalX = gameWidth / 5;
  static const _labelFontSize = 10.0;
  static const _labelRightPadding = 4.0;

  late final Paint _bgPaint;
  late final Paint _gridPaint;
  final List<_GridLine> _gridLines = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2.zero();
    size = Vector2(gameWidth, stageHeight + groundHeight);

    _bgPaint = Paint()..color = _bgColor;
    _gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1.0;

    // グリッド線の位置と価格ラベルを事前計算
    final maxJsonY = stageHeight / 3;
    var jsonY = (maxJsonY / _gridIntervalJson).floor() * _gridIntervalJson;
    while (jsonY >= 0) {
      final flameY = stageHeight - jsonY * 3;
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
      )
        ..pushStyle(ui.TextStyle(
          color: _labelColor,
          fontSize: _labelFontSize,
        ))
        ..addText(jsonY.round().toString());
      final para = pb.build()..layout(const ui.ParagraphConstraints(width: 60));
      _gridLines.add(_GridLine(flameY: flameY, paragraph: para));
      jsonY -= _gridIntervalJson;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bgPaint);

    // X軸方向の補助線（縦線）：pipeScrollOffset に同期してスクロール
    final scrollOffset = game.pipeScrollOffset % _gridIntervalX;
    var x = _gridIntervalX - scrollOffset;
    while (x < size.x) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);
      x += _gridIntervalX;
    }

    // Y軸方向の補助線（横線）と価格ラベル
    for (final line in _gridLines) {
      canvas.drawLine(
        Offset(0, line.flameY),
        Offset(size.x, line.flameY),
        _gridPaint,
      );
      // 右端に価格ラベル
      canvas.drawParagraph(
        line.paragraph,
        Offset(
          size.x - line.paragraph.longestLine - _labelRightPadding,
          line.flameY - line.paragraph.height / 2,
        ),
      );
    }
  }
}

class _GridLine {
  final double flameY;
  final ui.Paragraph paragraph;
  const _GridLine({required this.flameY, required this.paragraph});
}
