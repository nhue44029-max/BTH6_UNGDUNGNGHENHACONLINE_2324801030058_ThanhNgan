import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';

class LibraryException implements Exception {
  const LibraryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Keeps exactly one favorites listener and one playlists listener per user.
/// This avoids opening a Firestore listener for every song card on screen.
class LibraryService extends ChangeNotifier {
  LibraryService({required this.firebaseReady}) {
    if (!firebaseReady) return;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _bindUser,
    );
    _bindUser(FirebaseAuth.instance.currentUser);
  }

  static const _writeTimeout = Duration(seconds: 12);
  final bool firebaseReady;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _playlistsSub;
  String? _boundUid;
  Set<String> _favoriteIds = <String>{};
  List<SongModel> _favoriteSongs = const [];
  List<PlaylistModel> _playlistItems = const [];
  final Map<String, bool> _pendingFavorites = <String, bool>{};
  final Map<String, SongModel> _pendingSongs = <String, SongModel>{};
  bool _syncing = false;
  String? _syncError;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<SongModel> get favoriteSongs => List.unmodifiable(_favoriteSongs);
  List<PlaylistModel> get playlistItems => List.unmodifiable(_playlistItems);
  bool get syncing => _syncing;
  String? get syncError => _syncError;
  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);
  bool isFavoriteBusy(String trackId) => _pendingFavorites.containsKey(trackId);

  String get _uid {
    final uid = firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;
    if (uid == null) {
      throw const LibraryException('Bạn cần đăng nhập để lưu âm nhạc.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

  CollectionReference<Map<String, dynamic>> _playlists(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('playlists');

  void _bindUser(User? user) {
    final uid = user?.uid;
    if (_boundUid == uid) return;
    _boundUid = uid;
    unawaited(_favoritesSub?.cancel());
    unawaited(_playlistsSub?.cancel());
    _favoriteIds = <String>{};
    _favoriteSongs = const [];
    _playlistItems = const [];
    _pendingFavorites.clear();
    _pendingSongs.clear();
    _syncError = null;
    _syncing = uid != null;
    notifyListeners();

    if (uid == null) return;
    _favoritesSub = _favorites(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .listen(_applyFavorites, onError: _handleSyncError);
    _playlistsSub = _playlists(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(_applyPlaylists, onError: _handleSyncError);
  }

  void _applyFavorites(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final ids = snapshot.docs.map((doc) => doc.id).toSet();
    final songs = <String, SongModel>{
      for (final doc in snapshot.docs)
        doc.id: SongModel.fromFirestore(doc.data()),
    };
    for (final entry in _pendingFavorites.entries) {
      if (entry.value) {
        ids.add(entry.key);
        final pendingSong = _pendingSongs[entry.key];
        if (pendingSong != null) songs[entry.key] = pendingSong;
      } else {
        ids.remove(entry.key);
        songs.remove(entry.key);
      }
    }
    _favoriteIds = ids;
    _favoriteSongs = songs.values.toList(growable: false);
    _syncing = false;
    _syncError = null;
    notifyListeners();
  }

  void _applyPlaylists(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _playlistItems = snapshot.docs
        .map(PlaylistModel.fromDocument)
        .toList(growable: false);
    _syncing = false;
    _syncError = null;
    notifyListeners();
  }

  void _handleSyncError(Object error, StackTrace stackTrace) {
    _syncing = false;
    _syncError = _friendlyMessage(error);
    notifyListeners();
  }

  Future<void> toggleFavorite(SongModel song) async {
    if (_pendingFavorites.containsKey(song.id)) return;
    final uid = _uid;
    final wasFavorite = _favoriteIds.contains(song.id);
    final target = !wasFavorite;
    _pendingFavorites[song.id] = target;
    _pendingSongs[song.id] = song;
    if (target) {
      _favoriteIds = {..._favoriteIds, song.id};
      _favoriteSongs = [
        song,
        ..._favoriteSongs.where((item) => item.id != song.id),
      ];
    } else {
      _favoriteIds = {..._favoriteIds}..remove(song.id);
      _favoriteSongs = _favoriteSongs
          .where((item) => item.id != song.id)
          .toList(growable: false);
    }
    notifyListeners();

    final ref = _favorites(uid).doc(song.id);
    try {
      if (target) {
        await ref
            .set({
              ...song.toFirestore(),
              'addedAt': FieldValue.serverTimestamp(),
            })
            .timeout(_writeTimeout);
      } else {
        await ref.delete().timeout(_writeTimeout);
      }
    } catch (error) {
      if (wasFavorite) {
        _favoriteIds = {..._favoriteIds, song.id};
        _favoriteSongs = [
          song,
          ..._favoriteSongs.where((item) => item.id != song.id),
        ];
      } else {
        _favoriteIds = {..._favoriteIds}..remove(song.id);
        _favoriteSongs = _favoriteSongs
            .where((item) => item.id != song.id)
            .toList(growable: false);
      }
      throw LibraryException(_friendlyMessage(error));
    } finally {
      _pendingFavorites.remove(song.id);
      _pendingSongs.remove(song.id);
      notifyListeners();
    }
  }

  Future<String> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const LibraryException('Tên playlist không được để trống.');
    }
    try {
      final ref = await _playlists(_uid).add({
        'name': trimmedName,
        'trackIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_writeTimeout);
      return ref.id;
    } catch (error) {
      throw LibraryException(_friendlyMessage(error));
    }
  }

  Future<void> addToPlaylist(String playlistId, SongModel song) async {
    final p = _playlists(_uid).doc(playlistId);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(p.collection('tracks').doc(song.id), {
      ...song.toFirestore(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    batch.update(p, {
      'trackIds': FieldValue.arrayUnion([song.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await batch.commit().timeout(_writeTimeout);
    } catch (error) {
      throw LibraryException(_friendlyMessage(error));
    }
  }

  Stream<List<SongModel>> playlistSongs(String id) => _playlists(_uid)
      .doc(id)
      .collection('tracks')
      .orderBy('addedAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc.data()))
            .toList(),
      );

  Future<void> removeFromPlaylist(String id, String trackId) async {
    final p = _playlists(_uid).doc(id);
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(p.collection('tracks').doc(trackId));
    batch.update(p, {
      'trackIds': FieldValue.arrayRemove([trackId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    try {
      await batch.commit().timeout(_writeTimeout);
    } catch (error) {
      throw LibraryException(_friendlyMessage(error));
    }
  }

  Future<void> deletePlaylist(String id) async {
    final p = _playlists(_uid).doc(id);
    try {
      final tracks = await p.collection('tracks').get().timeout(_writeTimeout);
      final batch = FirebaseFirestore.instance.batch();
      for (final track in tracks.docs) {
        batch.delete(track.reference);
      }
      batch.delete(p);
      await batch.commit().timeout(_writeTimeout);
    } catch (error) {
      throw LibraryException(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(Object error) {
    if (error is TimeoutException) {
      return 'Kết nối Firestore quá chậm. Vui lòng kiểm tra mạng và thử lại.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore từ chối quyền ghi. Hãy kiểm tra Rules và trạng thái đăng nhập.';
        case 'unavailable':
          return 'Firestore đang không khả dụng. Vui lòng kiểm tra kết nối mạng.';
        case 'unauthenticated':
          return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
    }
    return 'Không thể đồng bộ thư viện. Vui lòng thử lại.';
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    unawaited(_favoritesSub?.cancel());
    unawaited(_playlistsSub?.cancel());
    super.dispose();
  }
}
