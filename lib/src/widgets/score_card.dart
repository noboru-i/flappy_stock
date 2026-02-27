import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key, required this.score});

  final ValueNotifier<int> score;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Text(
          'SCORE: $value',
          style: GoogleFonts.pressStart2p(
            fontSize: 18,
            color: const Color(0xff184e77),
          ),
        ),
      ),
    );
  }
}
