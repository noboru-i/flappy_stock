import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/ranking_service.dart';

class RankingList extends StatelessWidget {
  const RankingList({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RANKING',
          style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: StreamBuilder<List<RankingEntry>>(
            stream: RankingService.instance.getRanking(stageId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF26A69A)),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text(
                    'ERROR',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: Colors.red,
                    ),
                  ),
                );
              }
              final entries = snapshot.data!;
              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    'NO SCORES YET',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: Colors.white38,
                    ),
                  ),
                );
              }
              final currentUid = AuthService.instance.currentUser?.uid;
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isMe = entry.uid == currentUid;
                  return _RankingRow(
                    rank: index + 1,
                    entry: entry,
                    isMe: isMe,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  final int rank;
  final RankingEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final color = isMe ? const Color(0xFF26A69A) : Colors.white70;
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Colors.white38,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: isMe
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF26A69A), width: 1),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: GoogleFonts.pressStart2p(fontSize: 8, color: rankColor),
            ),
          ),
          if (entry.photoURL != null)
            ClipOval(
              child: Image.network(
                entry.photoURL!,
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.account_circle,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
            )
          else
            const Icon(Icons.account_circle, size: 16, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.displayName,
              style: GoogleFonts.pressStart2p(fontSize: 7, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '¥${entry.finalValue.toStringAsFixed(0)}',
            style: GoogleFonts.pressStart2p(fontSize: 8, color: color),
          ),
        ],
      ),
    );
  }
}
