import 'dart:convert';
import 'package:flutter/services.dart';
import 'pipe_data.dart';
import '../config.dart';

class PipeLoader {
  static Future<List<StageData>> load() async {
    final raw = await rootBundle.loadString('assets/data/pipes.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final stages = (json['stages'] as List)
        .map((s) => StageData.fromJson(s as Map<String, dynamic>))
        .toList();

    // バリデーション
    for (final stage in stages) {
      for (final pipe in stage.pipes) {
        assert(
          pipe.gapCenterY > pipeGap / 2 &&
          pipe.gapCenterY < gameHeight - groundHeight - pipeGap / 2,
          '[${stage.id}] gapCenterY out of range: ${pipe.gapCenterY}',
        );
      }
    }
    return stages;
  }
}
