import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/library_service.dart';
import 'auth_gate.dart';

Future<void> showPlaylistPicker(BuildContext context, SongModel song) async {
  if (!await requireAccount(context) || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PlaylistPickerSheet(song: song),
  );
}

class _PlaylistPickerSheet extends StatefulWidget {
  const _PlaylistPickerSheet({required this.song});
  final SongModel song;

  @override
  State<_PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<_PlaylistPickerSheet> {
  String? _busyPlaylistId;
  bool _creating = false;

  Future<void> _addTo(String playlistId) async {
    if (_busyPlaylistId != null || _creating) return;
    setState(() => _busyPlaylistId = playlistId);
    try {
      await context.read<LibraryService>().addToPlaylist(
        playlistId,
        widget.song,
      );
      if (mounted) Navigator.pop(context);
    } on LibraryException catch (error) {
      if (mounted) {
        setState(() => _busyPlaylistId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _createAndAdd() async {
    final name = await _askPlaylistName();
    if (!mounted || name == null) return;
    setState(() => _creating = true);
    try {
      final service = context.read<LibraryService>();
      final id = await service.createPlaylist(name);
      await service.addToPlaylist(id, widget.song);
      if (mounted) Navigator.pop(context);
    } on LibraryException catch (error) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<String?> _askPlaylistName() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Playlist mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Tên playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final playlists = context.select<LibraryService, List<PlaylistModel>>(
      (service) => service.playlistItems,
    );
    final syncing = context.select<LibraryService, bool>(
      (service) => service.syncing,
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thêm vào playlist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _creating || _busyPlaylistId != null
                    ? null
                    : _createAndAdd,
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _creating ? 'Đang tạo và thêm bài...' : 'Tạo playlist mới',
                ),
              ),
              if (syncing && playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Bạn chưa có playlist nào.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final busy = _busyPlaylistId == playlist.id;
                      return ListTile(
                        leading: busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.queue_music_rounded),
                        title: Text(playlist.name),
                        subtitle: Text(
                          busy
                              ? 'Đang thêm bài hát...'
                              : '${playlist.trackIds.length} bài hát',
                        ),
                        enabled: _busyPlaylistId == null && !_creating,
                        onTap: () => _addTo(playlist.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
