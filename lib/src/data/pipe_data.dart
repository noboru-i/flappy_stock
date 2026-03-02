class CandleData {
  const CandleData({
    required this.spawnX,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    this.xLabel,
  });

  final double spawnX;

  /// ヒゲ上端（JSON座標：画面下端=0）
  final double high;

  /// ヒゲ下端（JSON座標：画面下端=0）
  final double low;

  /// 始値（JSON座標）
  final double open;

  /// 終値（JSON座標）
  final double close;

  /// X軸ラベル（例: yyyy/MM/dd）。表示不要な場合は null。
  final String? xLabel;

  factory CandleData.fromJson(Map<String, dynamic> json) => CandleData(
    spawnX: (json['spawnX'] as num).toDouble(),
    high: (json['high'] as num).toDouble(),
    low: (json['low'] as num).toDouble(),
    open: (json['open'] as num).toDouble(),
    close: (json['close'] as num).toDouble(),
    xLabel: json['xLabel'] as String?,
  );
}

class StageData {
  const StageData({
    required this.id,
    required this.name,
    required this.pipeSpeed,
    required this.candles,
    required this.yMin,
    required this.yMax,
  });

  final String id;
  final String name;
  final double pipeSpeed;
  final List<CandleData> candles;

  /// 表示 Y 範囲の下限（JSON 座標）。PipeLoader が計算してセットする。
  final double yMin;

  /// 表示 Y 範囲の上限（JSON 座標）。PipeLoader が計算してセットする。
  final double yMax;

  factory StageData.fromJson(Map<String, dynamic> json) => StageData(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? json['id'] as String,
    pipeSpeed: (json['pipeSpeed'] as num).toDouble(),
    candles: (json['candles'] as List)
        .map((c) => CandleData.fromJson(c as Map<String, dynamic>))
        .toList(),
    yMin: 0.0, // PipeLoader._normalizeYScale で上書きされる
    yMax: 0.0, // PipeLoader._normalizeYScale で上書きされる
  );
}
