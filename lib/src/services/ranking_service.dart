import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class RankingEntry {
  const RankingEntry({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.stageId,
    required this.finalValue,
    required this.createdAt,
  });

  final String uid;
  final String displayName;
  final String? photoURL;
  final String stageId;
  final double finalValue;
  final DateTime createdAt;

  factory RankingEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingEntry(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String,
      photoURL: data['photoURL'] as String?,
      stageId: data['stageId'] as String,
      finalValue: (data['finalValue'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class RankingService {
  RankingService._();
  static final instance = RankingService._();

  final _db = FirebaseFirestore.instance;

  Future<void> submitScore(String stageId, double finalValue) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    await _db.collection('scores').add({
      'uid': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Anonymous',
      'photoURL': user.photoURL,
      'stageId': stageId,
      'finalValue': finalValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<RankingEntry>> getRanking(String stageId) {
    return _db
        .collection('scores')
        .where('stageId', isEqualTo: stageId)
        .orderBy('finalValue', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(RankingEntry.fromDoc).toList());
  }
}
