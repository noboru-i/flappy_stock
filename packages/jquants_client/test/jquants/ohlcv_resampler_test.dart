import 'package:test/test.dart';
import 'package:jquants_client/jquants/ohlcv_model.dart';
import 'package:jquants_client/jquants/ohlcv_resampler.dart';

OhlcvData _day(String date, double open, double high, double low, double close, double volume) {
  return OhlcvData(
    date: DateTime.parse(date),
    open: open,
    high: high,
    low: low,
    close: close,
    volume: volume,
  );
}

void main() {
  group('OhlcvResampler', () {
    test('空リストを渡した場合、空リストが返ること', () {
      expect(OhlcvResampler.resample([], ResamplePeriod.weekly), isEmpty);
      expect(OhlcvResampler.resample([], ResamplePeriod.monthly), isEmpty);
    });

    test('日足5日分（月〜金）→ 週足1本に正しく集計されること', () {
      // 2024-01-08（月）〜 2024-01-12（金）
      final daily = [
        _day('2024-01-08', 100.0, 110.0, 95.0, 105.0, 1000.0),
        _day('2024-01-09', 105.0, 115.0, 100.0, 110.0, 1200.0),
        _day('2024-01-10', 110.0, 120.0, 105.0, 108.0, 900.0),
        _day('2024-01-11', 108.0, 112.0,  98.0, 115.0, 1100.0),
        _day('2024-01-12', 115.0, 118.0, 107.0, 112.0, 800.0),
      ];

      final weekly = OhlcvResampler.resample(daily, ResamplePeriod.weekly);

      expect(weekly.length, 1);
      final w = weekly.first;
      expect(w.date, DateTime.parse('2024-01-08'));
      expect(w.open, 100.0);   // 月曜の始値
      expect(w.high, 120.0);   // 週中の最大高値
      expect(w.low, 95.0);     // 週中の最小安値
      expect(w.close, 112.0);  // 金曜の終値
      expect(w.volume, 5000.0); // 5日分の合計
    });

    test('日足1ヶ月分 → 月足1本に集計されること', () {
      // 2024-01 の営業日（簡易的に5日分）
      final daily = [
        _day('2024-01-04', 200.0, 210.0, 195.0, 205.0, 500.0),
        _day('2024-01-05', 205.0, 215.0, 200.0, 210.0, 600.0),
        _day('2024-01-09', 210.0, 220.0, 205.0, 215.0, 550.0),
        _day('2024-01-10', 215.0, 225.0, 210.0, 220.0, 700.0),
        _day('2024-01-11', 220.0, 230.0, 215.0, 225.0, 650.0),
      ];

      final monthly = OhlcvResampler.resample(daily, ResamplePeriod.monthly);

      expect(monthly.length, 1);
      final m = monthly.first;
      expect(m.date, DateTime.parse('2024-01-04'));
      expect(m.open, 200.0);    // 最初の始値
      expect(m.high, 230.0);    // 最大高値
      expect(m.low, 195.0);     // 最小安値
      expect(m.close, 225.0);   // 最後の終値
      expect(m.volume, 3000.0); // 合計出来高
    });

    test('週またぎのデータが正しく2本に分割されること', () {
      // 2024-01-12（金）と 2024-01-15（月）
      final daily = [
        _day('2024-01-12', 100.0, 110.0, 95.0, 105.0, 1000.0),  // 週1（W02）
        _day('2024-01-15', 105.0, 115.0, 100.0, 110.0, 1200.0), // 週2（W03）
      ];

      final weekly = OhlcvResampler.resample(daily, ResamplePeriod.weekly);

      expect(weekly.length, 2);
      expect(weekly[0].open, 100.0);
      expect(weekly[0].close, 105.0);
      expect(weekly[1].open, 105.0);
      expect(weekly[1].close, 110.0);
    });

    test('月またぎのデータが正しく2本に分割されること', () {
      final daily = [
        _day('2024-01-31', 100.0, 110.0, 95.0, 105.0, 1000.0),
        _day('2024-02-01', 105.0, 115.0, 100.0, 110.0, 1200.0),
      ];

      final monthly = OhlcvResampler.resample(daily, ResamplePeriod.monthly);

      expect(monthly.length, 2);
      expect(monthly[0].date, DateTime.parse('2024-01-31'));
      expect(monthly[1].date, DateTime.parse('2024-02-01'));
    });
  });
}
