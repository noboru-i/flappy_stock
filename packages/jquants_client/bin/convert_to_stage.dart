import 'dart:convert';
import 'dart:io';

/// 株価データ（output/{code}/{period}.json）をステージ形式
/// （assets/data/pipes/{code}_{period}.json）に変換する。
///
/// Usage（jquants_client ディレクトリで実行）:
///   dart run bin/convert_to_stage.dart [output-dir]
///
/// output-dir のデフォルトは ../../assets/data/pipes
///
/// 変換ルール:
///   spawnX  = 日付の Unix タイムスタンプ（秒）
///   high    = high 値そのまま
///   low     = low 値そのまま
///   open    = open 値そのまま
///   close   = close 値そのまま
///
/// y 座標がゲーム表示範囲を超える場合や変化量が小さすぎる場合は、
/// ゲーム実行時にスケーリングで対応する（issue #2）。
void main(List<String> args) async {
  final destPath = args.isNotEmpty ? args[0] : '../../assets/data/pipes';

  final inputDir = Directory('output');
  if (!inputDir.existsSync()) {
    stderr.writeln('Error: output/ directory not found. Run from jquants_client root.');
    exit(1);
  }

  final destDir = Directory(destPath);
  await destDir.create(recursive: true);

  const encoder = JsonEncoder.withIndent('  ');
  var convertedCount = 0;

  await for (final codeEntry in inputDir.list()) {
    if (codeEntry is! Directory) continue;
    final code = codeEntry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);

    await for (final file in codeEntry.list()) {
      if (file is! File) continue;
      if (!file.path.endsWith('.json')) continue;

      final period = file.uri.pathSegments.last.replaceAll('.json', '');
      final id = '${code}_$period';

      print('Converting $code/$period.json -> $destPath/$id.json ...');

      final raw = await file.readAsString();
      final records = jsonDecode(raw) as List<dynamic>;

      final candles = records.map((dynamic r) {
        final map = r as Map<String, dynamic>;
        final date = DateTime.parse(map['date'] as String);
        // Unix タイムスタンプ（秒）を spawnX として利用
        final spawnX = date.millisecondsSinceEpoch ~/ 1000;
        return {
          'spawnX': spawnX,
          'high': (map['high'] as num).toDouble(),
          'low': (map['low'] as num).toDouble(),
          'open': (map['open'] as num).toDouble(),
          'close': (map['close'] as num).toDouble(),
        };
      }).toList();

      final stage = {
        'id': id,
        'name': '$code ${_capitalize(period)}',
        'pipeSpeed': 150.0,
        'candles': candles,
      };

      final outFile = File('$destPath/$id.json');
      await outFile.writeAsString(encoder.convert(stage));
      print('  -> saved ${outFile.path} (${candles.length} candles)');
      convertedCount++;
    }
  }

  print('\nDone. $convertedCount file(s) converted.');
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
