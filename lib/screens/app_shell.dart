import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../core/app_colors.dart';
import '../widgets/mini_player.dart';
import 'discover_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.firebaseError});
  final Object? firebaseError;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  static const _pages = [
    HomeScreen(),
    DiscoverScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final error = context.select<AudioPlayerController, String?>(
      (player) => player.error,
    );
    return Scaffold(
      body: Column(
        children: [
          if (widget.firebaseError != null)
            MaterialBanner(
              content: const Text(
                'Firebase chưa khởi tạo được. Nghe nhạc Audius vẫn hoạt động; đăng nhập và thư viện tạm thời không khả dụng.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          if (error != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFE6E9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
