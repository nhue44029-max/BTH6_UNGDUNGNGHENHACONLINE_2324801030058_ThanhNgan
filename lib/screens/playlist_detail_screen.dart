import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/library_service.dart';
import '../widgets/song_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlist});
  final PlaylistModel playlist;
  @override
  Widget build(BuildContext context) {
    final service = context.read<LibraryService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            tooltip: 'Xóa playlist',
            onPressed: () => _delete(context, service),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<SongModel>>(
        stream: service.playlistSongs(playlist.id),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Không thể tải playlist.'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final songs = snapshot.data!;
          if (songs.isEmpty)
            return const Center(child: Text('Playlist này chưa có bài hát.'));
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => SongTile(
              song: songs[index],
              queue: songs,
              index: index,
              trailing: IconButton(
                tooltip: 'Xóa khỏi playlist',
                onPressed: () =>
                    service.removeFromPlaylist(playlist.id, songs[index].id),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, LibraryService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa playlist?'),
        content: Text(
          'Playlist “${playlist.name}” sẽ bị xóa. Các bài hát trên Audius không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.deletePlaylist(playlist.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
