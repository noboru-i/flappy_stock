import 'dart:convert';
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
    for (final stage in stages) {
      for (final pipe in stage.pipes) {
        assert(
          pipe.gapTop >= 0 &&
          pipe.gapBottom > pipe.gapTop &&
          pipe.gapBottom <= gameHeight - groundHeight,
          '[${stage.id}] gapTop/gapBottom out of range: ${pipe.gapTop} / ${pipe.gapBottom}',
        );
      }
    }
    return stages;
  }
}
