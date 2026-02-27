class OhlcvData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const OhlcvData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// V2 API レスポンス形式からパース
  /// フィールド名: Date, O, H, L, C, Vo
  factory OhlcvData.fromJson(Map<String, dynamic> json) {
    return OhlcvData(
      date: DateTime.parse(json['Date'] as String),
      open: (json['O'] as num).toDouble(),
      high: (json['H'] as num).toDouble(),
      low: (json['L'] as num).toDouble(),
      close: (json['C'] as num).toDouble(),
      volume: (json['Vo'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
      };

  @override
  String toString() =>
      'OhlcvData(date: $date, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
}
