import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../flappy_stock.dart';
import '../flappy_world.dart';

class Background extends PositionComponent with HasGameReference<FlappyStock> {
  static const _bgColor = Color(0xFF131722);
  static const _gridColor = Color(0xFF252540);
  static const _labelColor = Color(0xFF9CA0C2);

  // X軸グリッド間隔（Flame X座標単位：ゲーム幅 400px を 5 分割）
  static const _gridIntervalX = gameWidth / 5;
  static const _labelFontSize = 10.0;
  static const _labelRightPadding = 4.0;
  static const _xLabelFontSize = 10.0;
  static const _xLabelColor = Color(0xFF9CA0C2);
  static const _xLabelBottomPadding = 6.0;
  static const _xLabelMinSpacing = 56.0;

  late final Paint _bgPaint;
  late final Paint _gridPaint;
  final List<_GridLine> _gridLines = [];

  // グリッド再計算のトリガー用キャッシュ
  double _cachedYMin = double.infinity;
  double _cachedYMax = double.negativeInfinity;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2.zero();
    size = Vector2(gameWidth, stageHeight + groundHeight);

    _bgPaint = Paint()..color = _bgColor;
    _gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    final yMin = game.stageYMin;
    final yMax = game.stageYMax;
    if (yMin == _cachedYMin && yMax == _cachedYMax) return;

    _cachedYMin = yMin;
    _cachedYMax = yMax;
    _rebuildGridLines(yMin, yMax);
  }

  void _rebuildGridLines(double yMin, double yMax) {
    _gridLines.clear();
    final yRange = yMax - yMin;

    // Y軸グリッド間隔を表示範囲に応じて自動計算（約5〜10本になるよう）
    final rawInterval = yRange / 7;
    final magnitude = (rawInterval > 0)
        ? math.pow(10, (math.log(rawInterval) / math.ln10).floor()).toDouble()
        : 1.0;
    final normalized = rawInterval / magnitude;
    final niceInterval = normalized < 2
        ? magnitude
        : normalized < 5
        ? magnitude * 2
        : magnitude * 5;

    final firstY = (yMin / niceInterval).ceil() * niceInterval;
    var jsonY = firstY;
    while (jsonY <= yMax) {
      final flameY = stageHeight * (1 - (jsonY - yMin) / yRange);
      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
            )
            ..pushStyle(
              ui.TextStyle(color: _labelColor, fontSize: _labelFontSize),
            )
            ..addText(jsonY.round().toString());
      final para = pb.build()..layout(const ui.ParagraphConstraints(width: 60));
      _gridLines.add(_GridLine(flameY: flameY, paragraph: para));
      jsonY += niceInterval;
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

    // X軸の日付ラベル（実データステージのみ）
    final world = game.world as FlappyWorld;
    final candles = world.allCandles;
    if (candles.isEmpty) return;

    final viewportTop = game.camera.viewfinder.position.y;
    final labelY =
        viewportTop +
        gameHeight -
        groundHeight -
        _xLabelFontSize -
        _xLabelBottomPadding;
    var lastDrawnX = double.negativeInfinity;

    for (final candle in candles) {
      final label = candle.xLabel;
      if (label == null) continue;

      final candleCenterX =
          candle.spawnX - world.traveledX + gameWidth + pipeWidth * 1.5;
      if (candleCenterX < -pipeWidth || candleCenterX > gameWidth + pipeWidth) {
        continue;
      }
      if (candleCenterX - lastDrawnX < _xLabelMinSpacing) continue;

      final pb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
            )
            ..pushStyle(
              ui.TextStyle(color: _xLabelColor, fontSize: _xLabelFontSize),
            )
            ..addText(label);
      final para = pb.build()..layout(const ui.ParagraphConstraints(width: 80));

      final drawX = candleCenterX - para.longestLine / 2;
      canvas.drawParagraph(para, Offset(drawX, labelY));
      lastDrawnX = candleCenterX;
    }
  }
}

class _GridLine {
  final double flameY;
  final ui.Paragraph paragraph;
  const _GridLine({required this.flameY, required this.paragraph});
}
