import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../flappy_stock.dart';
import 'ranking_list.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key, required this.game, required this.onClose});

  final FlappyStock game;
  final VoidCallback onClose;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final stages = widget.game.stages;
    final titleStyle = GoogleFonts.pressStart2p(
      fontSize: 16,
      color: const Color(0xff184e77),
    );
    final stageNameStyle = GoogleFonts.pressStart2p(
      fontSize: 9,
      color: const Color(0xff184e77),
    );

    return Container(
      color: Colors.white.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xff184e77),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('RANKING', style: titleStyle),
                ],
              ),
            ),
            if (stages.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'NO STAGES',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final selected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xff184e77)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff184e77),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            stages[index].name,
                            style: stageNameStyle.copyWith(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xff184e77),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: RankingList(
                    stageId: stages[_selectedIndex].id,
                    flexible: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
