import 'dart:convert';
import 'dart:io';
import 'package:jquants_client/jquants_client.dart';

/// 動作確認用スクリプト
/// 環境変数 JQUANTS_API_KEY をセットして実行してください:
///
///   JQUANTS_API_KEY=your_api_key dart run
///
void main(List<String> arguments) async {
  final apiKey = Platform.environment['JQUANTS_API_KEY'];

  if (apiKey == null) {
    stderr.writeln(
      'Error: JQUANTS_API_KEY environment variable must be set.',
    );
    exit(1);
  }

  final service = JQuantsService(apiKey: apiKey);

  final code = arguments.isNotEmpty ? arguments[0] : '5255';
  // サブスクリプション期間（〜2025-12-05）に合わせて固定
  final to = DateTime(2025, 12, 5);
  final from = to.subtract(const Duration(days: 365));

  final encoder = const JsonEncoder.withIndent('  ');
  final outputDir = Directory('output/$code');
  await outputDir.create(recursive: true);

  Future<void> saveJson(String filename, List<OhlcvData> data) async {
    final file = File('${outputDir.path}/$filename');
    await file.writeAsString(encoder.convert(data.map((e) => e.toJson()).toList()));
    print('  -> saved to ${file.path} (${data.length} records)');
  }

  print('Fetching daily quotes for $code ...');
  final daily = await service.fetchDaily(code, from, to);
  await saveJson('daily.json', daily);

  print('Fetching weekly quotes for $code ...');
  final weekly = await service.fetchWeekly(code, from, to);
  await saveJson('weekly.json', weekly);

  print('Fetching monthly quotes for $code ...');
  final monthly = await service.fetchMonthly(code, from, to);
  await saveJson('monthly.json', monthly);
}
