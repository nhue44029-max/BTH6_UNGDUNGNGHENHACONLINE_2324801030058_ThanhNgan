abstract final class AudiusConfig {
  static const String baseUrl = 'https://api.audius.co/v1';
  static const String apiKey = String.fromEnvironment('AUDIUS_API_KEY');
  static Uri endpoint(String path, [Map<String, String>? query]) {
    final parameters = <String, String>{...?query};
    // Audius API keys are supported in browser clients. Never use a bearer
    // token here: that would expose a secret in the compiled web app.
    if (apiKey.isNotEmpty) parameters.putIfAbsent('api_key', () => apiKey);
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: parameters.isEmpty ? null : parameters);
  }

  static Uri stream(String trackId) => endpoint('/tracks/$trackId/stream');
}
