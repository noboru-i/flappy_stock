class BonusZone {
  const BonusZone({required this.start, required this.end});

  /// ボーナスゾーンの上端 y 座標（ゲーム座標）。
  final double start;

  /// ボーナスゾーンの下端 y 座標（ゲーム座標）。
  final double end;

  factory BonusZone.fromJson(Map<String, dynamic> json) => BonusZone(
    start: (json['start'] as num).toDouble(),
    end:   (json['end']   as num).toDouble(),
  );
}

class PipeData {
  const PipeData({
    required this.spawnX,
    required this.gapTop,
    required this.gapBottom,
    this.bonusZoneTop,
    this.bonusZoneBottom,
  });

  final double spawnX;
  final double gapTop;
  final double gapBottom;

  /// ギャップ上端付近のボーナスゾーン（省略時はボーナスなし）。
  final BonusZone? bonusZoneTop;

  /// ギャップ下端付近のボーナスゾーン（省略時はボーナスなし）。
  final BonusZone? bonusZoneBottom;

  factory PipeData.fromJson(Map<String, dynamic> json) => PipeData(
    spawnX:          (json['spawnX']    as num).toDouble(),
    gapTop:          (json['gapTop']    as num).toDouble(),
    gapBottom:       (json['gapBottom'] as num).toDouble(),
    bonusZoneTop:    json['bonusZoneTop']    != null
        ? BonusZone.fromJson(json['bonusZoneTop']    as Map<String, dynamic>)
        : null,
    bonusZoneBottom: json['bonusZoneBottom'] != null
        ? BonusZone.fromJson(json['bonusZoneBottom'] as Map<String, dynamic>)
        : null,
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
