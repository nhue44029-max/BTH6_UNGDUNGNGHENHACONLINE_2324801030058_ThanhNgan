import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/audius_config.dart';
import '../models/song_model.dart';

class AudiusException implements Exception {
  const AudiusException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AudiusService {
  AudiusService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<List<SongModel>> trending({int limit = 20}) => _getTracks(
    AudiusConfig.endpoint('/tracks/trending', {'limit': '$limit'}),
  );
  Future<List<SongModel>> search(String query, {int limit = 20}) {
    final value = query.trim();
    if (value.isEmpty) return Future.value(const []);
    return _getTracks(
      AudiusConfig.endpoint('/tracks/search', {
        'query': value,
        'limit': '$limit',
      }),
    );
  }

  Future<List<SongModel>> category({
    String? mood,
    String? genre,
    int limit = 20,
  }) {
    if (mood == null && genre == null) return trending(limit: limit);
    return _getTracks(
      AudiusConfig.endpoint('/tracks/search', {
        if (mood != null) 'mood': mood,
        if (genre != null) 'genre': genre,
        'sort_method': 'popular',
        'limit': '$limit',
      }),
    );
  }

  Future<List<SongModel>> _getTracks(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 || response.statusCode == 403)
        throw const AudiusException(
          'Audius từ chối yêu cầu. Hãy kiểm tra API key.',
        );
      if (response.statusCode == 429)
        throw const AudiusException(
          'Audius đang giới hạn lượt gọi. Vui lòng thử lại sau.',
        );
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw AudiusException(
          'Không tải được nhạc (HTTP ${response.statusCode}).',
        );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['data'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SongModel.fromAudius)
          .where((song) => song.id.isNotEmpty && song.streamable)
          .toList(growable: false);
    } on SocketException {
      throw const AudiusException('Không có kết nối Internet.');
    } on FormatException {
      throw const AudiusException('Dữ liệu Audius trả về không hợp lệ.');
    } on AudiusException {
      rethrow;
    } catch (_) {
      throw const AudiusException(
        'Không thể kết nối Audius. Vui lòng thử lại.',
      );
    }
  }
}
