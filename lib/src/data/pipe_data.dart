class CandleData {
  const CandleData({
    required this.spawnX,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
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

  factory CandleData.fromJson(Map<String, dynamic> json) => CandleData(
    spawnX: (json['spawnX'] as num).toDouble(),
    high:   (json['high']   as num).toDouble(),
    low:    (json['low']    as num).toDouble(),
    open:   (json['open']   as num).toDouble(),
    close:  (json['close']  as num).toDouble(),
  );
}

class StageData {
  const StageData({
    required this.id,
    required this.pipeSpeed,
    required this.candles,
  });

  final String id;
  final double pipeSpeed;
  final List<CandleData> candles;

  factory StageData.fromJson(Map<String, dynamic> json) => StageData(
    id:        json['id'] as String,
    pipeSpeed: (json['pipeSpeed'] as num).toDouble(),
    candles: (json['candles'] as List)
        .map((c) => CandleData.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
