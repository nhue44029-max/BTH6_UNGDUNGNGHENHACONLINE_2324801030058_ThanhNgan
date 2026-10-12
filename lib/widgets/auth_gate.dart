import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../services/auth_service.dart';

Future<bool> requireAccount(BuildContext context) async {
  if (context.read<AuthService>().isSignedIn) return true;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đăng nhập để lưu âm nhạc của bạn'),
      content: const Text(
        'Đăng nhập hoặc tạo tài khoản Melumi để lưu bài hát yêu thích và playlist cá nhân.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Để sau'),
        ),
        TextButton(
          onPressed: () async {
            await Navigator.push(
              dialogContext,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
            if (dialogContext.mounted &&
                dialogContext.read<AuthService>().isSignedIn)
              Navigator.pop(dialogContext, true);
          },
          child: const Text('Đăng ký'),
        ),
        FilledButton(
          onPressed: () async {
            await Navigator.push(
              dialogContext,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
            if (dialogContext.mounted &&
                dialogContext.read<AuthService>().isSignedIn)
              Navigator.pop(dialogContext, true);
          },
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );
  return result ?? false;
}
