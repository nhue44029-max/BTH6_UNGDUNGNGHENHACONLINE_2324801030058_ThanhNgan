import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/audius_config.dart';
import '../models/song_model.dart';

/// A single player shared by the whole app.
///
/// We deliberately load one Audius source at a time. A trending/search result
/// can include an old, removed or access-gated track; creating one giant audio
/// playlist made that one bad URL fail the otherwise playable queue.
class AudioPlayerController extends ChangeNotifier {
  AudioPlayerController() {
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _playing = state.playing;
        _processingState = state.processingState;
        notifyListeners();
        if (!_changingSource &&
            _sourceReady &&
            state.processingState == ProcessingState.completed) {
          unawaited(_advanceAfterCompletion());
        }
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen((_) {
        // Load errors are handled by _playAt. Do not show a different song
        // while the player is still outputting sound from the previous one.
        if (!_changingSource) _handlePlaybackError(_requestId);
      }),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<SongModel> _queue = const [];
  int _index = -1;
  SongModel? _currentSong;
  bool _playing = false;
  bool _changingSource = false;
  bool _sourceReady = false;
  bool _advancing = false;
  ProcessingState _processingState = ProcessingState.idle;
  String? _error;
  int _requestId = 0;

  AudioPlayer get player => _player;
  SongModel? get current => _currentSong;
  bool get playing => _playing;
  bool get changingSource => _changingSource;
  bool get loading =>
      _changingSource ||
      _processingState == ProcessingState.loading ||
      _processingState == ProcessingState.buffering;
  bool get hasNext =>
      !_changingSource && _index >= 0 && _index < _queue.length - 1;
  bool get hasPrevious => !_changingSource && _index > 0;
  String? get error => _error;

  Future<bool> playQueue(List<SongModel> songs, int index) async {
    if (songs.isEmpty || index < 0 || index >= songs.length) return false;
    _queue = List.unmodifiable(songs);
    return _playAt(index, allowSkip: false);
  }

  Future<bool> _playAt(int index, {required bool allowSkip}) async {
    if (index < 0 || index >= _queue.length) return false;
    final request = ++_requestId;
    final song = _queue[index];
    _error = null;
    _changingSource = true;
    _sourceReady = false;
    notifyListeners();
    try {
      // Stop the old audio before the artwork/title switches to this song.
      await _player.stop();
      if (request != _requestId) return false;
      _index = index;
      _currentSong = song;
      notifyListeners();
      await _player.setAudioSource(
        AudioSource.uri(AudiusConfig.stream(song.id), tag: song.id),
        initialPosition: Duration.zero,
      );
      if (request != _requestId) return false;
      _sourceReady = true;
      _changingSource = false;
      notifyListeners();
      // just_audio's play() future completes at the END of playback. Waiting
      // here used to leave the previous request active for the entire song.
      unawaited(
        _player.play().catchError((Object _) {
          _handlePlaybackError(request);
        }),
      );
      return true;
    } catch (_) {
      if (request != _requestId) return false;
      if (allowSkip && index + 1 < _queue.length) {
        return _playAt(index + 1, allowSkip: true);
      }
      _error = 'Bài này hiện không có luồng âm thanh khả dụng trên Audius.';
      _sourceReady = false;
      notifyListeners();
      return false;
    } finally {
      if (request == _requestId) {
        _changingSource = false;
        notifyListeners();
      }
    }
  }

  void _handlePlaybackError(int request) {
    if (request != _requestId || !_sourceReady) return;
    _sourceReady = false;
    _error = 'Luồng âm thanh của bài này bị gián đoạn. Vui lòng thử lại hoặc chọn bài khác.';
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_changingSource) return;
    if (!_sourceReady) {
      if (_index >= 0) await _playAt(_index, allowSkip: false);
      return;
    }
    _error = null;
    notifyListeners();
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      final request = _requestId;
      unawaited(
        _player.play().catchError((Object _) {
          _handlePlaybackError(request);
        }),
      );
    }
  }

  Future<void> next() async {
    if (hasNext) await _playAt(_index + 1, allowSkip: true);
  }

  Future<void> previous() async {
    if (hasPrevious) {
      await _playAt(_index - 1, allowSkip: true);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> _advanceAfterCompletion() async {
    if (_advancing || !hasNext) return;
    _advancing = true;
    try {
      await next();
    } finally {
      _advancing = false;
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
