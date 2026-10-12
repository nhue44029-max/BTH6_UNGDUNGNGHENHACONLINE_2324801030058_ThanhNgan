import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService({required this.firebaseReady}) {
    if (firebaseReady) {
      _subscription = FirebaseAuth.instance.authStateChanges().listen((value) {
        _user = value;
        notifyListeners();
      });
      _user = FirebaseAuth.instance.currentUser;
    }
  }
  final bool firebaseReady;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _busy = false;
  String? _error;
  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;
  Future<bool> signIn(String email, String password) => _run(
    () async => FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );
  Future<bool> register(String name, String email, String password) =>
      _run(() async {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
        await credential.user?.updateDisplayName(name.trim());
        await _ensureProfile(credential.user, fallbackName: name.trim());
        await credential.user?.sendEmailVerification();
      });
  Future<bool> signInWithGoogle() => _run(() async {
    final provider = GoogleAuthProvider();
    final credential = kIsWeb
        ? await FirebaseAuth.instance.signInWithPopup(provider)
        : await FirebaseAuth.instance.signInWithProvider(provider);
    await _ensureProfile(credential.user);
  });
  Future<bool> resetPassword(String email) => _run(
    () => FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim()),
  );
  Future<void> resendVerification() async => _user?.sendEmailVerification();
  Future<void> signOut() async {
    if (firebaseReady) await FirebaseAuth.instance.signOut();
  }

  Future<void> _ensureProfile(User? user, {String? fallbackName}) async {
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists)
      await ref.set({
        'name': user.displayName ?? fallbackName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (!firebaseReady) {
      _error = 'Firebase chưa sẵn sàng. Hãy kiểm tra cấu hình dự án.';
      notifyListeners();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      _error = _messageFor(error.code);
      return false;
    } catch (_) {
      _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _messageFor(String code) => switch (code) {
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'invalid-email' => 'Địa chỉ email không hợp lệ.',
    'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
    'popup-closed-by-user' ||
    'canceled-popup-request' => 'Bạn đã hủy đăng nhập Google.',
    'network-request-failed' => 'Không có kết nối mạng.',
    'too-many-requests' => 'Thao tác quá nhiều lần. Vui lòng thử lại sau.',
    _ => 'Không thể xác thực ($code).',
  };
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
