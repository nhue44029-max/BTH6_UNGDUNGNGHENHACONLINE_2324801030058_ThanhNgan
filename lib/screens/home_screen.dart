import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../core/app_colors.dart';
import '../models/song_model.dart';
import '../services/audius_service.dart';
import '../services/auth_service.dart';
import '../widgets/artwork.dart';
import '../widgets/song_tile.dart';
import 'discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<SongModel>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<AudiusService>().trending();
  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    return RefreshIndicator(
      onRefresh: () async {
        _retry();
        await _future;
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD8F4FF),
                    AppColors.background,
                    Color(0xFFF9FDFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Melumi',
                                    style: TextStyle(
                                      fontSize: 45,
                                      height: 1,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Âm nhạc cho những ngày dịu dàng hơn',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              backgroundImage: user?.photoURL == null
                                  ? null
                                  : NetworkImage(user!.photoURL!),
                              child: user?.photoURL == null
                                  ? Icon(
                                      user == null
                                          ? Icons.person_outline_rounded
                                          : Icons.person_rounded,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          readOnly: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const DiscoverScreen(standalone: true),
                            ),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm bài hát, nghệ sĩ...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<SongModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const SizedBox(
                    height: 360,
                    child: Center(child: CircularProgressIndicator()),
                  );
                if (snapshot.hasError)
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _retry,
                  );
                final songs = snapshot.data ?? const [];
                if (songs.isEmpty)
                  return _ErrorState(
                    message: 'Audius chưa trả về bài hát phù hợp.',
                    onRetry: _retry,
                  );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroCard(
                            song: songs.first,
                            onPlay: () => context
                                .read<AudioPlayerController>()
                                .playQueue(songs, 0),
                          ),
                          const SizedBox(height: 18),
                          const SizedBox(height: 90, child: _MoodStrip()),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Đang thịnh hành',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ),
                              const Text(
                                'Từ Audius',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            songs.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: SongTile(
                                song: songs[index],
                                queue: songs,
                                index: index,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.song, required this.onPlay});
  final SongModel song;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xFFB8E9FF), Color(0xFF74C8F5), Color(0xFF2785D4)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .16),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GỢI Ý DỊU DÀNG HÔM NAY',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 27,
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(song.artist, style: const TextStyle(color: AppColors.text)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Nghe ngay'),
            ),
          ],
        );
        return compact
            ? Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  Artwork(url: song.artworkUrl, size: 112, radius: 24),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 3, child: info),
                  const SizedBox(width: 30),
                  Artwork(url: song.artworkUrl, size: 190, radius: 30),
                ],
              );
      },
    ),
  );
}

class _MoodStrip extends StatelessWidget {
  const _MoodStrip();
  static const items = [
    (Icons.favorite_rounded, 'Dành cho bạn', 'Easygoing', null),
    (Icons.eco_rounded, 'Thư giãn', 'Peaceful', null),
    (Icons.nightlight_round, 'Buổi tối', null, 'Ambient'),
    (Icons.local_cafe_rounded, 'Làm việc', null, 'Lo-Fi'),
    (Icons.trending_up_rounded, 'Top thịnh hành', null, null),
  ];
  @override
  Widget build(BuildContext context) => ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(width: 10),
    itemBuilder: (context, index) {
      final item = items[index];
      return SizedBox(
        width: 125,
        child: Material(
          color: Colors.white.withValues(alpha: .72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
            side: const BorderSide(color: Colors.white),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscoverScreen(
                  standalone: true,
                  categoryTitle: item.$2,
                  categoryMood: item.$3,
                  categoryGenre: item.$4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, color: AppColors.primaryLight),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    maxLines: 1,
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          size: 54,
          color: AppColors.secondaryText,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}
