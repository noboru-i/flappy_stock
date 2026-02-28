import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../flappy_stock.dart';
import 'score_card.dart';
import 'overlay_screen.dart';
import 'stage_select_screen.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  // build の外で生成（毎フレーム再生成を防ぐ）
  late final FlappyStock _game = FlappyStock();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff1a1a2e),
        body: SafeArea(
          child: Column(
            children: [
              ScoreCard(score: _game.score),
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: 400,
                      height: 700,
                      child: GameWidget(
                        game: _game,
                        overlayBuilderMap: {
                          PlayState.welcome.name: (_, _) =>
                              const OverlayScreen(
                                title: 'FLAPPY STOCK',
                                subtitle: 'TAP TO START',
                              ),
                          PlayState.stageSelect.name: (_, game) =>
                              StageSelectScreen(game: game as FlappyStock),
                          PlayState.gameOver.name: (_, _) =>
                              const OverlayScreen(
                                title: 'GAME OVER',
                                subtitle: 'TAP TO RETRY',
                              ),
                          PlayState.clear.name: (_, game) {
                            final flappyStock = game as FlappyStock;
                            return OverlayScreen(
                              title: 'STAGE CLEAR!',
                              subtitle: 'TAP TO RETRY',
                              score: flappyStock.score.value,
                            );
                          },
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
