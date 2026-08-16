import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/notes/screens/notes_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: WriteBookMobileApp(),
    ),
  );
}

class WriteBookMobileApp extends ConsumerWidget {
  const WriteBookMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'WriteBook Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.amber500,
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const NotesScreen();
    }

    return const LoginScreen();
  }
}
