import 'package:flutter_test/flutter_test.dart';
import 'package:melumi/core/audius_config.dart';
import 'package:melumi/models/song_model.dart';

void main() {
  test('phân tích track Audius thật đúng cấu trúc', () {
    final song = SongModel.fromAudius({
      'id': 'GEG9ZWx',
      'title': 'Rowsfred - CLAWN',
      'duration': 210,
      'is_streamable': true,
      'user': {'name': 'ROWSFRED'},
      'artwork': {'480x480': 'https://example.com/art.jpg'},
    });
    expect(song.id, 'GEG9ZWx');
    expect(song.artist, 'ROWSFRED');
    expect(song.duration, const Duration(seconds: 210));
  });

  test('stream URL luôn trỏ tới endpoint Audius HTTPS', () {
    final uri = AudiusConfig.stream('GEG9ZWx');
    expect(uri.scheme, 'https');
    expect(uri.host, 'api.audius.co');
    expect(uri.path, '/v1/tracks/GEG9ZWx/stream');
  });

  test('mỗi track Audius dùng đúng ID riêng trong URL stream', () {
    final first = AudiusConfig.stream('GEG9ZWx');
    final second = AudiusConfig.stream('J72oWO6');
    expect(first, isNot(second));
    expect(first.pathSegments, contains('GEG9ZWx'));
    expect(second.pathSegments, contains('J72oWO6'));
  });
}
