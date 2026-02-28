import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'pipe_data.dart';
import '../config.dart';

class PipeLoader {
  static Future<List<StageData>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest
        .listAssets()
        .where((k) => k.startsWith('assets/data/pipes/') && k.endsWith('.json'))
        .toList()
      ..sort();

    final stages = <StageData>[];
    for (final key in keys) {
      final raw = await rootBundle.loadString(key);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      stages.add(StageData.fromJson(json));
    }

    // バリデーション
    final maxY = gameHeight - groundHeight;
    for (final stage in stages) {
      for (final candle in stage.candles) {
        final minBody = math.min(candle.open, candle.close);
        final maxBody = math.max(candle.open, candle.close);
        assert(
          candle.low >= 0 &&
          candle.high <= maxY &&
          candle.low <= minBody &&
          maxBody <= candle.high,
          '[${stage.id}] candle data out of range: '
          'high=${candle.high} low=${candle.low} '
          'open=${candle.open} close=${candle.close}',
        );
      }
    }
    return stages;
  }
}
