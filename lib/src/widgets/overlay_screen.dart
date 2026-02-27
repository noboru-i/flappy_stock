import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.pressStart2p(
      fontSize: 28,
      color: const Color(0xff184e77),
    );
    final subStyle = GoogleFonts.pressStart2p(
      fontSize: 14,
      color: const Color(0xff184e77),
    );

    return Container(
      alignment: const Alignment(0, -0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: titleStyle)
              .animate()
              .slideY(duration: 750.ms, begin: -3, end: 0),
          const SizedBox(height: 24),
          Text(subtitle, style: subStyle)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
        ],
      ),
    );
  }
}
