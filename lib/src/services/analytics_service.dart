import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final _analytics = FirebaseAnalytics.instance;

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logSelectStage(String stageId, String stageName) async {
    await _analytics.logEvent(
      name: 'select_stage',
      parameters: {'stage_id': stageId, 'stage_name': stageName},
    );
  }

  Future<void> logStageClear({
    required String stageId,
    required double finalValue,
  }) async {
    await _analytics.logEvent(
      name: 'stage_clear',
      parameters: {
        'stage_id': stageId,
        'final_value': finalValue.round(),
      },
    );
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }
}
