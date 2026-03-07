import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/ranking_service.dart';
import '../utils.dart';

class RankingList extends StatelessWidget {
  const RankingList({super.key, required this.stageId, this.flexible = false});

  final String stageId;

  /// true のとき、リストを Expanded で高さいっぱいに広げる（flex 親が必要）。
  /// false（デフォルト）のとき、固定高さ 160 を使用。
  final bool flexible;

  Widget _buildList() {
    return StreamBuilder<List<RankingEntry>>(
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
              style: GoogleFonts.pressStart2p(fontSize: 8, color: Colors.red),
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
            return _RankingRow(rank: index + 1, entry: entry, isMe: isMe);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (flexible) return _buildList();
    return SizedBox(height: 160, child: _buildList());
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
    final color = isMe ? const Color(0xFF26A69A) : Colors.black87;
    final rankColor = switch (rank) {
      1 => const Color(0xFFD4A000),
      2 => const Color(0xFF808080),
      3 => const Color(0xFF8B4513),
      _ => Colors.black45,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: GoogleFonts.pressStart2p(fontSize: 10, color: rankColor),
            ),
          ),
          if (entry.photoURL != null)
            ClipOval(
              child: Image.network(
                entry.photoURL!,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.account_circle,
                  size: 20,
                  color: Colors.black38,
                ),
              ),
            )
          else
            const Icon(Icons.account_circle, size: 20, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.displayName,
              style: GoogleFonts.pressStart2p(fontSize: 9, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatCurrency(entry.finalValue),
            style: GoogleFonts.pressStart2p(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
