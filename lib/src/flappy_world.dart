import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'flappy_stock.dart';
import 'config.dart';
import 'data/pipe_data.dart';
import 'data/pipe_loader.dart';
import 'components/components.dart';

class FlappyWorld extends World
    with TapCallbacks, HasGameReference<FlappyStock> {

  List<StageData> _stages = [];
  List<StageData> get stages => _stages;
  StageData? _currentStage;

  // 未出現ローソク足のキュー（spawnX 昇順）
  final List<CandleData> _pendingCandles = [];

  // 鳥の仮想累積移動距離
  double _traveledX = 0;
  double get traveledX => _traveledX;

  // クリア判定用カウンタ
  int _totalCandles = 0;
  int _scoredCandles = 0;

  // 現在の鳥への参照（スコア判定に使用）
  Bird? _bird;

  @override
  FutureOr<void> onLoad() async {
    _stages = await PipeLoader.load();
    add(Background());
    add(Ground());
  }

  // ─── ゲーム開始 ────────────────────────────────────────────────
  void startGame(StageData stage) {
    removeAll(children.query<Bird>());
    removeAll(children.query<Candle>());

    game.score.value = 0;
    _traveledX = 0;
    _scoredCandles = 0;

    _currentStage = stage;
    _totalCandles = _currentStage!.candles.length;

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
      add(Candle(
        high:      data.high,
        low:       data.low,
        open:      data.open,
        close:     data.close,
        speed:     speed,
        getBirdY:  () => _bird?.y ?? stageHeight / 2,
        onScored:  _onCandleScored,
      ));
    }
  }

  void _onCandleScored() {
    _scoredCandles++;
    if (_scoredCandles >= _totalCandles) {
      game.playState = PlayState.clear;
    }
  }

  // ─── タップ入力 ────────────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (game.playState == PlayState.playing) {
      children.query<Bird>().firstOrNull?.flapStart();
    } else if (game.playState == PlayState.welcome ||
               game.playState == PlayState.gameOver ||
               game.playState == PlayState.clear) {
      game.playState = PlayState.stageSelect;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (game.playState == PlayState.playing) {
      children.query<Bird>().firstOrNull?.flapEnd();
    }
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    if (game.playState == PlayState.playing) {
      children.query<Bird>().firstOrNull?.flapEnd();
    }
  }
}
