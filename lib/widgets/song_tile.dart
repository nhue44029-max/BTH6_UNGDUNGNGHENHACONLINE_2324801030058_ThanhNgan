import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../core/app_colors.dart';
import '../models/song_model.dart';
import '../services/auth_service.dart';
import '../services/library_service.dart';
import 'artwork.dart';
import 'auth_gate.dart';
import 'playlist_picker.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.trailing,
  });
  final SongModel song;
  final List<SongModel> queue;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final playerState = context.select<AudioPlayerController, (bool, bool)>(
      (player) => (player.current?.id == song.id, player.playing),
    );
    final current = playerState.$1;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () =>
            context.read<AudioPlayerController>().playQueue(queue, index),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Artwork(url: song.artworkUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              if (current)
                Icon(
                  playerState.$2
                      ? Icons.graphic_eq_rounded
                      : Icons.pause_rounded,
                  color: AppColors.primary,
                ),
              FavoriteButton(song: song),
              IconButton(
                tooltip: 'Thêm vào playlist',
                onPressed: () => showPlaylistPicker(context, song),
                icon: const Icon(Icons.playlist_add_rounded),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.song});
  final SongModel song;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isSignedIn) {
      return IconButton(
        tooltip: 'Yêu thích',
        icon: const Icon(Icons.favorite_border_rounded),
        onPressed: () async {
          if (await requireAccount(context) && context.mounted)
            await context.read<LibraryService>().toggleFavorite(song);
        },
      );
    }
    final state = context.select<LibraryService, (bool, bool)>(
      (service) => (
        service.isFavorite(song.id),
        service.isFavoriteBusy(song.id),
      ),
    );
    final selected = state.$1;
    final busy = state.$2;
    return IconButton(
      tooltip: selected ? 'Bỏ yêu thích' : 'Yêu thích',
      onPressed: busy
          ? null
          : () async {
              try {
                await context.read<LibraryService>().toggleFavorite(song);
              } on LibraryException catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              }
            },
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              selected
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: selected ? Colors.pinkAccent : null,
            ),
    );
  }
}
