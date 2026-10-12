import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../core/app_colors.dart';
import '../screens/player_screen.dart';
import 'artwork.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();
    final song = controller.current;
    if (song == null) return const SizedBox.shrink();
    return Material(
      color: AppColors.creamWhite,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<Duration>(
              stream: controller.player.positionStream,
              builder: (context, snapshot) {
                final total = controller.changingSource
                    ? song.duration
                    : controller.player.duration ?? song.duration;
                final position = controller.changingSource
                    ? Duration.zero
                    : snapshot.data ?? Duration.zero;
                final value = total.inMilliseconds == 0
                    ? 0.0
                    : position.inMilliseconds / total.inMilliseconds;
                return LinearProgressIndicator(
                  value: value.clamp(0, 1),
                  minHeight: 2,
                  backgroundColor: AppColors.lightBlue,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Artwork(url: song.artworkUrl, size: 48, radius: 12),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: controller.hasPrevious
                        ? controller.previous
                        : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  if (controller.loading)
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton.filled(
                      onPressed: controller.toggle,
                      icon: Icon(
                        controller.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  IconButton(
                    onPressed: controller.hasNext ? controller.next : null,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
