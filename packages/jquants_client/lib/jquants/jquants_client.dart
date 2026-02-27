import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jquants_auth.dart';
import 'ohlcv_model.dart';

class JQuantsClient {
  static const _baseUrl = 'https://api.jquants.com/v2';

  final JQuantsAuth _auth;

  JQuantsClient(this._auth);

  Future<List<OhlcvData>> fetchDailyQuotes({
    required String code,
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = _formatDate(from);
    final toStr = _formatDate(to);

    final uri = Uri.parse(
      '$_baseUrl/equities/bars/daily?code=$code&from=$fromStr&to=$toStr',
    );

    final response = await http.get(
      uri,
      headers: {'x-api-key': _auth.apiKey},
    ).catchError((e) => throw Exception('Network error: $e'));

    if (response.statusCode != 200) {
      throw JQuantsApiException(response.statusCode, response.body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final quotes = body['data'] as List<dynamic>;
    return quotes
        .map((q) => OhlcvData.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
