import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/song_model.dart';
import '../services/audius_service.dart';
import '../widgets/song_tile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.standalone = false,
    this.categoryTitle,
    this.categoryMood,
    this.categoryGenre,
  });
  final bool standalone;
  final String? categoryTitle;
  final String? categoryMood;
  final String? categoryGenre;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<SongModel> _songs = const [];
  bool _loading = true;
  String? _error;
  int _requestId = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInitial();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() => _run(() {
    final audius = context.read<AudiusService>();
    return audius.category(
      mood: widget.categoryMood,
      genre: widget.categoryGenre,
    );
  });
  Future<void> _searchNow(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 550), () {
      if (value.trim().isEmpty) {
        _loadInitial();
      } else {
        _run(() => context.read<AudiusService>().search(value));
      }
    });
  }

  Future<void> _run(Future<List<SongModel>> Function() action) async {
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final songs = await action();
      if (mounted && request == _requestId) setState(() => _songs = songs);
    } catch (error) {
      if (mounted && request == _requestId) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && request == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.standalone
        ? AppBar(
            backgroundColor: Colors.transparent,
            title: Text(widget.categoryTitle ?? 'Khám phá'),
          )
        : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.standalone)
                      Text(
                        'Khám phá',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      autofocus:
                          widget.standalone && widget.categoryTitle == null,
                      onChanged: _searchNow,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Tìm bài hát, nghệ sĩ bạn yêu thích...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  _loadInitial();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 6,
                ),
                child: Text(
                  _search.text.trim().isEmpty
                      ? widget.categoryTitle ?? 'Nhạc thịnh hành'
                      : 'Kết quả tìm kiếm',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _loadInitial,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _songs.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy bài hát phù hợp.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        itemCount: _songs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => SongTile(
                          song: _songs[index],
                          queue: _songs,
                          index: index,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
