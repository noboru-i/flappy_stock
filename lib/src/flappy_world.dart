import 'dart:async';
import 'package:flame/components.dart';
import 'flappy_stock.dart';
import 'config.dart';
import 'data/news_data.dart';
import 'data/news_loader.dart';
import 'data/pipe_data.dart';
import 'data/pipe_loader.dart';
import 'components/components.dart';

class FlappyWorld extends World with HasGameReference<FlappyStock> {
  static const _newsBubbleHalfWidth = 130.0;
  static const _newsBubbleTailPadding = 12.0;

  List<StageData> _stages = [];
  List<StageData> get stages => _stages;
  StageData? _currentStage;
  String? get currentStageId => _currentStage?.id;
  Map<String, List<NewsData>> _currentStageNews = const {};
  final List<_ScheduledNewsBubble> _scheduledNews = <_ScheduledNewsBubble>[];
  int _nextScheduledNewsIndex = 0;
  final List<_ActiveNewsBubble> _activeNewsBubbles = <_ActiveNewsBubble>[];

  // stageId -> yyyy-MM-dd -> NewsData[]
  Map<String, Map<String, List<NewsData>>> _newsByStage = const {};

  // 未出現ローソク足のキュー（spawnX 昇順）
  final List<CandleData> _pendingCandles = [];

  // ステージ全ローソク足（ミニマップ用）
  List<CandleData> _allCandles = [];
  List<CandleData> get allCandles => _allCandles;

  // 鳥の仮想累積移動距離
  double _traveledX = 0;
  double get traveledX => _traveledX;

  // クリア判定用カウンタ
  int _totalCandles = 0;
  int _scoredCandles = 0;
  int _spawnedCandles = 0;

  // 現在の鳥への参照（スコア判定に使用）
  Bird? _bird;
  double get birdFlameY => _bird?.y ?? stageHeight / 2;

  // ステージの表示 Y 範囲（JSON 座標）
  double stageYMin = 0.0;
  double stageYMax = stageHeight / 3;

  @override
  FutureOr<void> onLoad() async {
    _stages = await PipeLoader.load();
    _newsByStage = await NewsLoader.loadGrouped();
    add(Background());
    add(Ground());
  }

  // ─── フラップ制御（FlappyStock 経由で呼ばれる）──────────────────────
  void flapStart() => children.query<Bird>().firstOrNull?.flapStart();
  void flapEnd() => children.query<Bird>().firstOrNull?.flapEnd();

  // ─── ゲーム開始 ────────────────────────────────────────────────
  void startGame(StageData stage) {
    removeAll(children.query<Bird>());
    removeAll(children.query<Candle>());

    // 取引状態を初期化
    game.shares.value = initialShares;
    game.cash.value = 0;
    game.tradeMode.value = TradeMode.sell;
    game.shortPosition.value = null;
    game.finalPrice = 0.0;

    _traveledX = 0;
    _scoredCandles = 0;
    _spawnedCandles = 0;

    _currentStage = stage;
    _currentStageNews = _newsByStage[stage.id] ?? const {};
    _scheduledNews
      ..clear()
      ..addAll(_buildScheduledNewsBubbles(stage, _currentStageNews));
    _nextScheduledNewsIndex = 0;
    _activeNewsBubbles.clear();
    game.newsTickerBubbles.value = const [];
    _totalCandles = _currentStage!.candles.length;
    _allCandles = List.unmodifiable(_currentStage!.candles);
    stageYMin = _currentStage!.yMin;
    stageYMax = _currentStage!.yMax;

    // キューを初期化
    _pendingCandles
      ..clear()
      ..addAll(_currentStage!.candles);

    game.playState = PlayState.playing;

    _bird = Bird(position: Vector2(gameWidth * 0.25, stageHeight / 2));
    add(_bird!);
  }

  // ─── ゲームループ ──────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    final speed = _currentStage?.pipeSpeed ?? pipeSpeed;
    _traveledX += speed * dt;
    _tryStartNewsTicker();
    _updateNewsBubbleX();

    // カメラが鳥のY座標を追従
    if (_bird != null) {
      final targetY = (_bird!.y - gameHeight / 2).clamp(
        0.0,
        stageHeight + groundHeight - gameHeight,
      );
      game.camera.viewfinder.position = Vector2(0, targetY);
    }

    // 出現タイミングに達したローソク足を追加
    while (_pendingCandles.isNotEmpty &&
        _traveledX >= _pendingCandles.first.spawnX) {
      final data = _pendingCandles.removeAt(0);
      _spawnedCandles++;
      final isLast = _spawnedCandles >= _totalCandles;
      add(
        Candle(
          high: data.high,
          low: data.low,
          open: data.open,
          close: data.close,
          speed: speed,
          isLast: isLast,
          getBirdY: () => _bird?.y ?? stageHeight / 2,
          onScored: _onCandleScored,
        ),
      );
    }
  }

  void _tryStartNewsTicker() {
    if (_scheduledNews.isEmpty) return;

    final offLeft = -_newsBubbleHalfWidth - _newsBubbleTailPadding;
    final offRight = gameWidth + _newsBubbleHalfWidth + _newsBubbleTailPadding;

    while (_nextScheduledNewsIndex < _scheduledNews.length) {
      final scheduled = _scheduledNews[_nextScheduledNewsIndex];
      final candleCenterX = _candleCenterX(scheduled.spawnX);
      if (candleCenterX > offRight) break;
      if (candleCenterX < offLeft) {
        _nextScheduledNewsIndex++;
        continue;
      }

      _activeNewsBubbles.add(
        _ActiveNewsBubble(spawnX: scheduled.spawnX, text: scheduled.text),
      );
      _nextScheduledNewsIndex++;
    }
  }

  void _updateNewsBubbleX() {
    if (_activeNewsBubbles.isEmpty) {
      if (game.newsTickerBubbles.value.isNotEmpty) {
        game.newsTickerBubbles.value = const [];
      }
      return;
    }

    final offLeft = -_newsBubbleHalfWidth - _newsBubbleTailPadding;
    final offRight = gameWidth + _newsBubbleHalfWidth + _newsBubbleTailPadding;

    _activeNewsBubbles.removeWhere((bubble) {
      final x = _candleCenterX(bubble.spawnX);
      return x < offLeft || x > offRight;
    });

    if (_activeNewsBubbles.isEmpty) {
      game.newsTickerBubbles.value = const [];
      return;
    }

    game.newsTickerBubbles.value = _activeNewsBubbles
        .map(
          (bubble) => NewsTickerBubble(
            text: bubble.text,
            centerX: _candleCenterX(bubble.spawnX),
          ),
        )
        .toList(growable: false);
  }

  double _candleCenterX(double spawnX) {
    return spawnX - _traveledX + gameWidth + pipeWidth * 1.5;
  }

  List<_ScheduledNewsBubble> _buildScheduledNewsBubbles(
    StageData stage,
    Map<String, List<NewsData>> stageNews,
  ) {
    if (stageNews.isEmpty) return const [];

    final anchors = <_CandleDateAnchor>[];
    for (final candle in stage.candles) {
      final label = candle.xLabel;
      if (label == null) continue;
      final parsed = _parseDateKey(NewsLoader.normalizeDateKey(label));
      if (parsed == null) continue;
      anchors.add(_CandleDateAnchor(date: parsed, spawnX: candle.spawnX));
    }
    if (anchors.isEmpty) return const [];
    anchors.sort((a, b) => a.date.compareTo(b.date));

    final scheduled = <_ScheduledNewsBubble>[];
    for (final entry in stageNews.entries) {
      final parsedNewsDate = _parseDateKey(entry.key);
      if (parsedNewsDate == null) continue;

      final spawnX = _interpolateSpawnX(parsedNewsDate, anchors);
      final text = entry.value.map((n) => n.summary).join('  /  ');
      scheduled.add(
        _ScheduledNewsBubble(spawnX: spawnX, text: '${entry.key}｜$text'),
      );
    }

    scheduled.sort((a, b) => a.spawnX.compareTo(b.spawnX));
    return scheduled;
  }

  double _interpolateSpawnX(DateTime target, List<_CandleDateAnchor> anchors) {
    final first = anchors.first;
    final last = anchors.last;
    if (!target.isAfter(first.date)) return first.spawnX;
    if (!target.isBefore(last.date)) return last.spawnX;

    for (var i = 0; i < anchors.length - 1; i++) {
      final left = anchors[i];
      final right = anchors[i + 1];
      final inRange =
          !target.isBefore(left.date) && !target.isAfter(right.date);
      if (!inRange) continue;

      final rangeMs =
          right.date.millisecondsSinceEpoch - left.date.millisecondsSinceEpoch;
      if (rangeMs <= 0) return right.spawnX;

      final offsetMs =
          target.millisecondsSinceEpoch - left.date.millisecondsSinceEpoch;
      final t = offsetMs / rangeMs;
      return left.spawnX + (right.spawnX - left.spawnX) * t;
    }

    return last.spawnX;
  }

  DateTime? _parseDateKey(String dateKey) {
    try {
      if (dateKey.length == 7) {
        return DateTime.parse('$dateKey-01');
      }
      return DateTime.parse(dateKey);
    } catch (_) {
      return null;
    }
  }

  void _onCandleScored(
    double jsonY,
    double high,
    double low,
    double close,
    bool isLast,
  ) {
    _scoredCandles++;
    final inRange = jsonY >= low && jsonY <= high;

    if (inRange) {
      final beforeShares = game.shares.value;
      final beforeCash = game.cash.value;

      final shortPos = game.shortPosition.value;
      if (shortPos != null) {
        // 空売り自動決済（通常取引は実行しない）
        game.cash.value -= shortPos.shares * jsonY;
        game.shortPosition.value = null;
      } else {
        // 通常取引
        switch (game.tradeMode.value) {
          case TradeMode.sell:
            if (game.shares.value > 0) {
              game.cash.value += game.shares.value * jsonY;
              game.shares.value = 0;
            }
          case TradeMode.buy:
            if (game.cash.value > 0) {
              game.shares.value += game.cash.value / jsonY;
              game.cash.value = 0;
            }
          case TradeMode.short:
            if (game.shortPosition.value == null) {
              game.cash.value += shortSellShares * jsonY;
              game.shortPosition.value = ShortPosition(
                price: jsonY,
                shares: shortSellShares,
              );
            }
        }
      }

      final increasedLabel = _buildIncreaseLabel(
        sharesDelta: game.shares.value - beforeShares,
        cashDelta: game.cash.value - beforeCash,
      );
      if (increasedLabel != null) {
        _showScorePopup(increasedLabel);
      }
    }

    if (_scoredCandles >= _totalCandles) {
      // 最終株価の決定（ヒゲ範囲内ならjsonY、範囲外ならclose）
      final finalPx = inRange ? jsonY : close;

      // 空売りポジション残存があれば強制決済
      final shortPos = game.shortPosition.value;
      if (shortPos != null) {
        game.cash.value -= shortPos.shares * finalPx;
        game.shortPosition.value = null;
      }

      game.finalPrice = finalPx;
      game.playState = PlayState.clear;
    }
  }

  String? _buildIncreaseLabel({
    required double sharesDelta,
    required double cashDelta,
  }) {
    if (sharesDelta > 0) {
      return '+${sharesDelta.toStringAsFixed(1)}株';
    }
    if (cashDelta > 0) {
      return '+¥${_formatCompactCash(cashDelta)}';
    }
    return null;
  }

  String _formatCompactCash(double value) {
    if (value >= 1000000) {
      final inM = (value / 1000000);
      final text = inM.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
      return '${text}M';
    }
    if (value >= 1000) {
      final inK = (value / 1000);
      final text = inK.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
      return '${text}k';
    }
    return value.round().toString();
  }

  void _showScorePopup(String label) {
    if (_bird == null) return;

    add(ScorePopup(text: label, position: _bird!.position.clone()));
  }
}

class _ActiveNewsBubble {
  const _ActiveNewsBubble({required this.spawnX, required this.text});

  final double spawnX;
  final String text;
}

class _ScheduledNewsBubble {
  const _ScheduledNewsBubble({required this.spawnX, required this.text});

  final double spawnX;
  final String text;
}

class _CandleDateAnchor {
  const _CandleDateAnchor({required this.date, required this.spawnX});

  final DateTime date;
  final double spawnX;
}
