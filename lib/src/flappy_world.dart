import 'dart:async';
import 'package:flame/components.dart';
import 'flappy_stock.dart';
import 'config.dart';
import 'data/pipe_data.dart';
import 'data/pipe_loader.dart';
import 'components/components.dart';

class FlappyWorld extends World with HasGameReference<FlappyStock> {

  List<StageData> _stages = [];
  List<StageData> get stages => _stages;
  StageData? _currentStage;
  String? get currentStageId => _currentStage?.id;

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

  @override
  FutureOr<void> onLoad() async {
    _stages = await PipeLoader.load();
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
    _totalCandles = _currentStage!.candles.length;
    _allCandles = List.unmodifiable(_currentStage!.candles);

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

    // カメラが鳥のY座標を追従
    if (_bird != null) {
      final targetY = (_bird!.y - gameHeight / 2)
          .clamp(0.0, stageHeight + groundHeight - gameHeight);
      game.camera.viewfinder.position = Vector2(0, targetY);
    }

    // 出現タイミングに達したローソク足を追加
    while (_pendingCandles.isNotEmpty &&
           _traveledX >= _pendingCandles.first.spawnX) {
      final data = _pendingCandles.removeAt(0);
      _spawnedCandles++;
      final isLast = _spawnedCandles >= _totalCandles;
      add(Candle(
        high:     data.high,
        low:      data.low,
        open:     data.open,
        close:    data.close,
        speed:    speed,
        isLast:   isLast,
        getBirdY: () => _bird?.y ?? stageHeight / 2,
        onScored: _onCandleScored,
      ));
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
}
