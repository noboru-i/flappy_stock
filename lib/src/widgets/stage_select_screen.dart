import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flappy_stock.dart';
import '../flappy_world.dart';

class StageSelectScreen extends StatelessWidget {
  const StageSelectScreen({super.key, required this.game});

  final FlappyStock game;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.pressStart2p(
      fontSize: 18,
      color: const Color(0xff184e77),
    );
    final stageNameStyle = GoogleFonts.pressStart2p(
      fontSize: 12,
      color: const Color(0xff184e77),
    );

    final stages = game.stages;

    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text('SELECT STAGE', style: titleStyle),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: const Color(0xff184e77),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          (game.world as FlappyWorld).startGame(stage);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.name,
                                style: stageNameStyle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              if (stage.candles.isNotEmpty &&
                                  stage.candles.first.xLabel != null &&
                                  stage.candles.last.xLabel != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${stage.candles.first.xLabel} ~ ${stage.candles.last.xLabel}',
                                  style: stageNameStyle.copyWith(
                                    color: Colors.white38,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
