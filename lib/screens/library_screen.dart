import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/library_service.dart';
import '../widgets/song_tile.dart';
import 'login_screen.dart';
import 'playlist_detail_screen.dart';
import 'register_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.isSignedIn) return const _GuestLibrary();
    final service = context.watch<LibraryService>();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Thư viện',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Playlist của bạn',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _createPlaylist(context, service),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tạo mới'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (service.syncError != null)
                Text(service.syncError!)
              else if (service.syncing && service.playlistItems.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (service.playlistItems.isEmpty)
                const _EmptyCard(
                  icon: Icons.queue_music_rounded,
                  text: 'Tạo playlist đầu tiên để gom những bài bạn yêu.',
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: service.playlistItems.map((playlist) {
                    return SizedBox(
                      width: 290,
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: const CircleAvatar(
                            child: Icon(Icons.queue_music_rounded),
                          ),
                          title: Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${playlist.trackIds.length} bài hát'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlist: playlist),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 28),
              Text(
                'Bài hát yêu thích',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (service.syncing && service.favoriteSongs.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (service.favoriteSongs.isEmpty)
                const _EmptyCard(
                  icon: Icons.favorite_border_rounded,
                  text: 'Những bài bạn thích sẽ xuất hiện tại đây.',
                )
              else
                Column(
                  children: List.generate(
                    service.favoriteSongs.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SongTile(
                        song: service.favoriteSongs[index],
                        queue: service.favoriteSongs,
                        index: index,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    LibraryService service,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Tên playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await service.createPlaylist(name);
    } on LibraryException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _GuestLibrary extends StatelessWidget {
  const _GuestLibrary();
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.lightBlue,
                  child: Icon(
                    Icons.library_music_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thư viện của riêng bạn',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Đăng nhập để lưu bài hát yêu thích và đồng bộ playlist. Bạn vẫn có thể quay lại nghe nhạc mà không cần tài khoản.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text('Đăng nhập'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text('Đăng ký'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    ),
  );
}
