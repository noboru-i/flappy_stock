import 'jquants_auth.dart';
import 'jquants_client.dart';
import 'ohlcv_model.dart';
import 'ohlcv_resampler.dart';

export 'jquants_auth.dart' show JQuantsApiException;
export 'ohlcv_model.dart';
export 'ohlcv_resampler.dart' show ResamplePeriod;

class JQuantsService {
  final JQuantsClient _client;

  JQuantsService({required String apiKey})
      : _client = JQuantsClient(JQuantsAuth(apiKey: apiKey));

  Future<List<OhlcvData>> fetchDaily(
    String code,
    DateTime from,
    DateTime to,
  ) {
    return _client.fetchDailyQuotes(code: code, from: from, to: to);
  }

  Future<List<OhlcvData>> fetchWeekly(
    String code,
    DateTime from,
    DateTime to,
  ) async {
    final daily = await _client.fetchDailyQuotes(code: code, from: from, to: to);
    return OhlcvResampler.resample(daily, ResamplePeriod.weekly);
  }

  Future<List<OhlcvData>> fetchMonthly(
    String code,
    DateTime from,
    DateTime to,
  ) async {
    final daily = await _client.fetchDailyQuotes(code: code, from: from, to: to);
    return OhlcvResampler.resample(daily, ResamplePeriod.monthly);
  }
}
