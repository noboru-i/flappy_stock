class JQuantsApiException implements Exception {
  final int statusCode;
  final String message;

  JQuantsApiException(this.statusCode, this.message);

  @override
  String toString() => 'JQuantsApiException($statusCode): $message';
}

class JQuantsAuth {
  final String apiKey;

  const JQuantsAuth({required this.apiKey});
}
