import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Cá nhân', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.lightBlue,
                        backgroundImage: user?.photoURL == null
                            ? null
                            : NetworkImage(user!.photoURL!),
                        child: user?.photoURL == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : user == null
                            ? 'Khách'
                            : 'Người dùng Melumi',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (user?.email != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            user!.email!,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (user == null) ...[
                        const Text(
                          'Tận hưởng âm nhạc theo cách riêng của bạn, đăng nhập để lưu giữ những giai điệu yêu thích và tạo playlist của riêng mình.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
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
                      ] else ...[
                        if (!user.emailVerified)
                          Card(
                            color: const Color(0xFFFFF4D8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.mark_email_unread_outlined,
                              ),
                              title: const Text('Email chưa được xác minh'),
                              subtitle: const Text(
                                'Hãy kiểm tra hộp thư hoặc gửi lại email xác minh.',
                              ),
                              trailing: TextButton(
                                onPressed: () async {
                                  await auth.resendVerification();
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã gửi lại email xác minh.',
                                        ),
                                      ),
                                    );
                                },
                                child: const Text('Gửi lại'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => auth.signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Đăng xuất'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Về bài thực hành',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Thanh Ngân · MSSV 2324801030058'),
                      Text('Lớp D23KTPM01'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
