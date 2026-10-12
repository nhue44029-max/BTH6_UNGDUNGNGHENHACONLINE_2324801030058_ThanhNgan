import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/audio_player_controller.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'services/audius_service.dart';
import 'services/auth_service.dart';
import 'services/library_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error;
  }
  runApp(MelumiApp(firebaseError: firebaseError));
}

class MelumiApp extends StatelessWidget {
  const MelumiApp({super.key, this.firebaseError});
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AudiusService()),
        ChangeNotifierProvider(
          create: (_) => AuthService(firebaseReady: firebaseError == null),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryService(firebaseReady: firebaseError == null),
        ),
        ChangeNotifierProvider(create: (_) => AudioPlayerController()),
      ],
      child: MaterialApp(
        title: 'Melumi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AppShell(firebaseError: firebaseError),
      ),
    );
  }
}
