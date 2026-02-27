import 'package:collection/collection.dart';
import 'ohlcv_model.dart';

enum ResamplePeriod { weekly, monthly }

class OhlcvResampler {
  static List<OhlcvData> resample(List<OhlcvData> daily, ResamplePeriod period) {
    if (daily.isEmpty) return [];

    final String Function(DateTime) keyFn =
        period == ResamplePeriod.weekly ? _weekKey : _monthKey;

    final grouped = groupBy(daily, (OhlcvData d) => keyFn(d.date));

    return grouped.entries.map((entry) {
      final candles = entry.value;
      return OhlcvData(
        date: candles.first.date,
        open: candles.first.open,
        high: candles.map((c) => c.high).reduce((a, b) => a > b ? a : b),
        low: candles.map((c) => c.low).reduce((a, b) => a < b ? a : b),
        close: candles.last.close,
        volume: candles.map((c) => c.volume).reduce((a, b) => a + b),
      );
    }).toList();
  }

  /// 例: "2024-W03"（ISO週、月曜始まり）
  static String _weekKey(DateTime date) {
    // ISO週番号の計算：木曜日が含まれる週がその年の週番号になる
    final thursday = date.subtract(Duration(days: date.weekday - 4));
    final firstThursdayOfYear = _firstThursdayOfYear(thursday.year);
    final weekNumber =
        ((thursday.difference(firstThursdayOfYear).inDays) ~/ 7) + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static DateTime _firstThursdayOfYear(int year) {
    final jan1 = DateTime(year, 1, 1);
    final daysUntilThursday = (4 - jan1.weekday + 7) % 7;
    return jan1.add(Duration(days: daysUntilThursday));
  }

  /// 例: "2024-01"
  static String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
