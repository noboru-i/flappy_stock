class PipeData {
  const PipeData({
    required this.spawnX,
    required this.gapTop,
    required this.gapBottom,
    this.bonusTop,
    this.bonusBottom,
  });

  final double spawnX;
  final double gapTop;
  final double gapBottom;

  /// 上ボーナスゾーンの下端 y 座標。gapTop〜bonusTop の範囲がボーナス（省略時はボーナスなし）。
  final double? bonusTop;

  /// 下ボーナスゾーンの上端 y 座標。bonusBottom〜gapBottom の範囲がボーナス（省略時はボーナスなし）。
  final double? bonusBottom;

  factory PipeData.fromJson(Map<String, dynamic> json) => PipeData(
    spawnX:      (json['spawnX']    as num).toDouble(),
    gapTop:      (json['gapTop']    as num).toDouble(),
    gapBottom:   (json['gapBottom'] as num).toDouble(),
    bonusTop:    json['bonusTop']    != null ? (json['bonusTop']    as num).toDouble() : null,
    bonusBottom: json['bonusBottom'] != null ? (json['bonusBottom'] as num).toDouble() : null,
  );
}

class StageData {
  const StageData({
    required this.id,
    required this.pipeSpeed,
    required this.pipes,
  });

  final String id;
  final double pipeSpeed;
  final List<PipeData> pipes;

  factory StageData.fromJson(Map<String, dynamic> json) => StageData(
    id:        json['id'] as String,
    pipeSpeed: (json['pipeSpeed'] as num).toDouble(),
    pipes: (json['pipes'] as List)
        .map((p) => PipeData.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}
