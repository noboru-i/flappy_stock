import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'pipe_data.dart';

class PipeLoader {
  /// 最初のローソク足が出現するまでの移動距離（ゲーム座標）
  static const _targetFirstSpawnX = 600.0;

  /// ローソク足間の目標間隔（ゲーム座標）
  static const _targetInterval = 450.0;

  /// これより大きい平均間隔は生データ（Unix タイムスタンプ等）と判断してスケーリングする
  static const _rawDataThreshold = 10000.0;

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
      stages.add(_normalizeYScale(_normalizeSpawnX(StageData.fromJson(json))));
    }

    // OHLC 整合性バリデーション（高値 >= 安値、ヒゲ範囲内にボディ）
    // 注意: 株価の生 y 座標はゲーム表示座標系に収まらない場合があり、
    //       表示時のスケーリングはゲーム実行時に行う（issue #2）。
    for (final stage in stages) {
      for (final candle in stage.candles) {
        final minBody = math.min(candle.open, candle.close);
        final maxBody = math.max(candle.open, candle.close);
        assert(
          candle.high >= candle.low &&
          candle.low <= minBody &&
          maxBody <= candle.high,
          '[${stage.id}] invalid OHLC: '
          'high=${candle.high} low=${candle.low} '
          'open=${candle.open} close=${candle.close}',
        );
      }
    }
    return stages;
  }

  /// spawnX をゲーム座標に正規化する。
  ///
  /// ローソク足間の平均間隔が [_rawDataThreshold] を超える場合（株価の Unix
  /// タイムスタンプ等の生データ）、以下の変換を適用する:
  ///   - 先頭ローソク足が [_targetFirstSpawnX] の位置に出現するようにオフセット補正
  ///   - 平均間隔が [_targetInterval] になるようにスケーリング
  ///
  /// すでにゲーム座標のステージ（チュートリアル等）はそのまま返す。
  static StageData _normalizeSpawnX(StageData stage) {
    final candles = stage.candles;
    if (candles.length < 2) return stage;

    final firstX = candles.first.spawnX;
    final lastX = candles.last.spawnX;
    final avgInterval = (lastX - firstX) / (candles.length - 1);

    if (avgInterval <= _rawDataThreshold) return stage;

    final scale = _targetInterval / avgInterval;
    final normalized = candles.map((c) => CandleData(
      spawnX: _targetFirstSpawnX + (c.spawnX - firstX) * scale,
      high: c.high,
      low: c.low,
      open: c.open,
      close: c.close,
    )).toList();

    return StageData(
      id: stage.id,
      name: stage.name,
      pipeSpeed: stage.pipeSpeed,
      candles: normalized,
      yMin: stage.yMin,
      yMax: stage.yMax,
    );
  }

  /// ステージ内の全ローソク足から Y 範囲を計算し、15% マージンを付与する。
  static StageData _normalizeYScale(StageData stage) {
    final candles = stage.candles;
    if (candles.isEmpty) return stage;

    var dataMin = candles.first.low;
    var dataMax = candles.first.high;
    for (final c in candles) {
      if (c.low  < dataMin) dataMin = c.low;
      if (c.high > dataMax) dataMax = c.high;
    }

    final range  = dataMax - dataMin;
    final margin = range * 0.15;

    return StageData(
      id:       stage.id,
      name:     stage.name,
      pipeSpeed: stage.pipeSpeed,
      candles:  stage.candles,
      yMin:     dataMin - margin,
      yMax:     dataMax + margin,
    );
  }
}
