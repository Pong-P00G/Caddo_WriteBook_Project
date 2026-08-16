import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Select Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(LucideIcons.sun, color: AppColors.amber500),
                  title: const Text('Light Mode'),
                  trailing: currentMode == ThemeMode.light
                      ? const Icon(LucideIcons.check, color: AppColors.amber500, size: 20)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.moon, color: AppColors.amber500),
                  title: const Text('Dark Mode'),
                  trailing: currentMode == ThemeMode.dark
                      ? const Icon(LucideIcons.check, color: AppColors.amber500, size: 20)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.smartphone, color: AppColors.amber500),
                  title: const Text('System Default'),
                  trailing: currentMode == ThemeMode.system
                      ? const Icon(LucideIcons.check, color: AppColors.amber500, size: 20)
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeProvider);

    String themeSubtitle = 'System Default';
    if (currentThemeMode == ThemeMode.light) {
      themeSubtitle = 'Light Mode';
    } else if (currentThemeMode == ThemeMode.dark) {
      themeSubtitle = 'Dark Mode';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Material(
                  color: isDark ? AppColors.ink900 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.ink800 : AppColors.ink200.withAlpha(204),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          size: 20,
                          color: AppColors.amber500,
                        ),
                        title: const Text('Theme'),
                        subtitle: Text(themeSubtitle),
                        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.ink400),
                        onTap: () => _showThemeSelector(context, ref, currentThemeMode),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(LucideIcons.info, size: 20),
                        title: Text('App Version'),
                        trailing: Text('1.0.0', style: TextStyle(color: AppColors.ink400)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
