import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../core/app_colors.dart';
import '../widgets/artwork.dart';
import '../widgets/playlist_picker.dart';
import '../widgets/song_tile.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();
    final song = controller.current;
    if (song == null)
      return const Scaffold(
        body: Center(child: Text('Hãy chọn một bài hát để nghe.')),
      );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Đang phát'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Artwork(
                  url: song.artworkUrl,
                  size: double.infinity,
                  radius: 36,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                song.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                song.artist,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<Duration>(
                stream: controller.player.positionStream,
                builder: (context, snapshot) {
                  final position = controller.changingSource
                      ? Duration.zero
                      : snapshot.data ?? Duration.zero;
                  final duration = controller.changingSource
                      ? song.duration
                      : controller.player.duration ?? song.duration;
                  return Column(
                    children: [
                      Slider(
                        value: position.inMilliseconds
                            .clamp(
                              0,
                              duration.inMilliseconds == 0
                                  ? 1
                                  : duration.inMilliseconds,
                            )
                            .toDouble(),
                        max: duration.inMilliseconds <= 0
                            ? 1
                            : duration.inMilliseconds.toDouble(),
                        onChanged: (value) => controller.seek(
                          Duration(milliseconds: value.round()),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_time(position)),
                          Text(_time(duration)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FavoriteButton(song: song),
                  IconButton(
                    iconSize: 38,
                    onPressed: controller.hasPrevious
                        ? controller.previous
                        : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  if (controller.loading)
                    const SizedBox(
                      width: 72,
                      height: 72,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    IconButton.filled(
                      iconSize: 42,
                      padding: const EdgeInsets.all(16),
                      onPressed: controller.toggle,
                      icon: Icon(
                        controller.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  IconButton(
                    iconSize: 38,
                    onPressed: controller.hasNext ? controller.next : null,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                  IconButton(
                    onPressed: () => showPlaylistPicker(context, song),
                    icon: const Icon(Icons.playlist_add_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
