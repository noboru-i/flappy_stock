import 'dart:convert';
import 'package:flutter/services.dart';
import 'news_data.dart';

class NewsLoader {
  static Future<Map<String, Map<String, List<NewsData>>>> loadGrouped() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys =
        manifest
            .listAssets()
            .where(
              (k) => k.startsWith('assets/data/news/') && k.endsWith('.json'),
            )
            .toList()
          ..sort();

    final grouped = <String, Map<String, List<NewsData>>>{};

    for (final key in keys) {
      final stageId = key.split('/').last.replaceAll('.json', '');
      final raw = await rootBundle.loadString(key);
      final json = jsonDecode(raw) as List<dynamic>;
      final list = json
          .map((e) => NewsData.fromJson(e as Map<String, dynamic>))
          .toList();

      final byDate = <String, List<NewsData>>{};
      for (final news in list) {
        final dateKey = _normalizeDateKey(news.date);
        byDate.putIfAbsent(dateKey, () => []).add(news);
      }
      grouped[stageId] = byDate;
    }

    return grouped;
  }

  static String normalizeDateKey(String input) => _normalizeDateKey(input);

  static String _normalizeDateKey(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 8) {
      final y = digits.substring(0, 4);
      final m = digits.substring(4, 6);
      final d = digits.substring(6, 8);
      return '$y-$m-$d';
    }
    return input;
  }
}
