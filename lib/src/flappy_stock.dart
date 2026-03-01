import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flappy_world.dart';
import 'config.dart';
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
    playState = PlayState.welcome;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        if (playState == PlayState.playing) {
          flapStart();
        } else if (playState == PlayState.welcome ||
                   playState == PlayState.gameOver ||
                   playState == PlayState.clear) {
          playState = PlayState.stageSelect;
        }
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        if (playState == PlayState.playing) {
          flapEnd();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Color backgroundColor() => const Color(0xff131722);
}
