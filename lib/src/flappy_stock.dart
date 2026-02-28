import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flappy_world.dart';
import 'components/bird.dart';
import 'config.dart';
import 'data/pipe_data.dart';

enum PlayState { welcome, stageSelect, playing, gameOver, clear }

class FlappyStock extends FlameGame with HasCollisionDetection, KeyboardEvents {
  FlappyStock()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
        world: FlappyWorld(),
      );

  // Flutter 状態管理との橋渡し
  final ValueNotifier<int> score = ValueNotifier(0);

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
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.stageSelect.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.clear.name);
    }
  }

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
      final flappyWorld = world as FlappyWorld;
      if (event is KeyDownEvent) {
        if (playState == PlayState.playing) {
          flappyWorld.children.query<Bird>().firstOrNull?.flapStart();
        } else if (playState == PlayState.welcome ||
                   playState == PlayState.gameOver ||
                   playState == PlayState.clear) {
          playState = PlayState.stageSelect;
        }
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        if (playState == PlayState.playing) {
          flappyWorld.children.query<Bird>().firstOrNull?.flapEnd();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Color backgroundColor() => const Color(0xff131722);
}
