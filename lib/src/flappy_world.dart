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
  StageData? _currentStage;

  // 未出現パイプのキュー（spawnX 昇順）
  final List<PipeData> _pendingPipes = [];

  // 鳥の仮想累積移動距離
  double _traveledX = 0;

  @override
  FutureOr<void> onLoad() async {
    _stages = await PipeLoader.load();
    add(Background());
    add(Ground());
  }

  // ─── ゲーム開始 ────────────────────────────────────────────────
  void startGame() {
    removeAll(children.query<Bird>());
    removeAll(children.query<PipePair>());

    game.score.value = 0;
    _traveledX = 0;

    // ステージ選択（現在は stage_01 固定。後で拡張可）
    _currentStage = _stages.first;

    // キューを初期化
    _pendingPipes
      ..clear()
      ..addAll(_currentStage!.pipes);

    game.playState = PlayState.playing;

    add(Bird(
      position: Vector2(gameWidth * 0.25, gameHeight * 0.45),
    ));
  }

  // ─── ゲームループ ──────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    final speed = _currentStage?.pipeSpeed ?? pipeSpeed;
    _traveledX += speed * dt;

    // 出現タイミングに達したパイプを追加
    while (_pendingPipes.isNotEmpty &&
           _traveledX >= _pendingPipes.first.spawnX) {
      final data = _pendingPipes.removeAt(0);
      add(PipePair(
        gapCenterY: data.gapCenterY,
        speed: speed,
      ));
    }
  }

  // ─── タップ入力 ────────────────────────────────────────────────
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (game.playState != PlayState.playing) {
      startGame();
    } else {
      children.query<Bird>().firstOrNull?.flapStart();
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
