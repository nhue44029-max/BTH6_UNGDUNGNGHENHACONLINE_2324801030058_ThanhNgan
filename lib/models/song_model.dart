class SongModel {
  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.duration,
    this.streamable = true,
  });
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final Duration duration;
  final bool streamable;

  factory SongModel.fromAudius(Map<String, dynamic> json) {
    final artwork = json['artwork'];
    final user = json['user'];
    var artworkUrl = '';
    if (artwork is Map)
      artworkUrl =
          (artwork['480x480'] ??
                  artwork['1000x1000'] ??
                  artwork['150x150'] ??
                  '')
              .toString();
    return SongModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Không rõ tên bài').toString(),
      artist: user is Map
          ? (user['name'] ?? user['handle'] ?? 'Nghệ sĩ Audius').toString()
          : 'Nghệ sĩ Audius',
      artworkUrl: artworkUrl,
      duration: Duration(seconds: (json['duration'] as num?)?.round() ?? 0),
      streamable:
          json['is_streamable'] != false && json['is_streamable'] != 'false',
    );
  }
  factory SongModel.fromFirestore(Map<String, dynamic> json) => SongModel(
    id: (json['trackId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    artist: (json['artist'] ?? '').toString(),
    artworkUrl: (json['artworkUrl'] ?? '').toString(),
    duration: Duration(seconds: (json['duration'] as num?)?.round() ?? 0),
  );
  Map<String, dynamic> toFirestore() => {
    'trackId': id,
    'title': title,
    'artist': artist,
    'artworkUrl': artworkUrl,
    'duration': duration.inSeconds,
  };
}
