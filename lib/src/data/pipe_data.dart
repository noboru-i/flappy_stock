class PipeData {
  const PipeData({
    required this.spawnX,
    required this.gapCenterY,
  });

  final double spawnX;
  final double gapCenterY;

  factory PipeData.fromJson(Map<String, dynamic> json) => PipeData(
    spawnX:     (json['spawnX']     as num).toDouble(),
    gapCenterY: (json['gapCenterY'] as num).toDouble(),
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
