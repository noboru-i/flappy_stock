import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flappy_world.dart';
import 'config.dart';
import 'components/components.dart';
import 'data/pipe_data.dart';

enum PlayState { welcome, stageSelect, playing, gameOver, clear }

enum TradeMode { buy, sell, short }

class ShortPosition {
  const ShortPosition({required this.price, required this.shares});
  final double price;
  final double shares;
}

class FlappyStock extends FlameGame with HasCollisionDetection, KeyboardEvents {
  FlappyStock()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
        world: FlappyWorld(),
      );

  // 取引状態
  final ValueNotifier<double> shares = ValueNotifier(initialShares);
  final ValueNotifier<double> cash = ValueNotifier(0.0);
  final ValueNotifier<TradeMode> tradeMode = ValueNotifier(TradeMode.sell);
  final ValueNotifier<ShortPosition?> shortPosition = ValueNotifier(null);
  double finalPrice = 0.0;
  double get finalValue => shares.value * finalPrice + cash.value;

  List<StageData> get stages => (world as FlappyWorld).stages;
  double get pipeScrollOffset => (world as FlappyWorld).traveledX;
  String? get currentStageId => (world as FlappyWorld).currentStageId;

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState state) {
    _playState = state;
    switch (state) {
      case PlayState.welcome:
      case PlayState.stageSelect:
      case PlayState.gameOver:
      case PlayState.clear:
        overlays.add(state.name);
        overlays.remove(PlayState.playing.name);
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.stageSelect.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.clear.name);
        overlays.add(PlayState.playing.name);
    }
  }

  void flapStart() => (world as FlappyWorld).flapStart();
  void flapEnd() => (world as FlappyWorld).flapEnd();

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport.add(MinimapComponent());
    playState = PlayState.welcome;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (playState != PlayState.playing) return KeyEventResult.ignored;

    // A/S/D キーをそれぞれのモードボタンに対応
    final modeForKey = switch (event.logicalKey) {
      LogicalKeyboardKey.keyA => TradeMode.buy,
      LogicalKeyboardKey.keyS => TradeMode.sell,
      LogicalKeyboardKey.keyD => TradeMode.short,
      _ => null,
    };
    if (modeForKey == null) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (!_isModeDisabled(modeForKey)) {
        tradeMode.value = modeForKey;
        flapStart();
      }
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      flapEnd();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// ボタンの無効化条件（playing_overlay.dart と同じロジック）
  bool _isModeDisabled(TradeMode mode) => switch (mode) {
    TradeMode.buy   => cash.value <= 0,
    TradeMode.sell  => shares.value <= 0,
    TradeMode.short => shortPosition.value != null,
  };

  @override
  Color backgroundColor() => const Color(0xff131722);
}
