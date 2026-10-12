import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.name,
    required this.trackIds,
  });
  final String id;
  final String name;
  final List<String> trackIds;
  factory PlaylistModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PlaylistModel(
      id: doc.id,
      name: (data['name'] ?? 'Playlist').toString(),
      trackIds: List<String>.from(data['trackIds'] as List? ?? const []),
    );
  }
}
