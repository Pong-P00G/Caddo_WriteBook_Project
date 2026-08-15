import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/providers/workspaces_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarController;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _avatarController = TextEditingController(text: user?.avatar ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() => _isSaving = true);
        final bytes = await pickedFile.readAsBytes();
        final fileName = pickedFile.name.isNotEmpty
            ? pickedFile.name
            : 'avatar.jpg';

        try {
          final formData = FormData.fromMap({
            'avatar': MultipartFile.fromBytes(bytes, filename: fileName),
          });

          final response = await ApiClient().dio.post(
            '/users/me/avatar',
            data: formData,
          );

          if (response.data['success'] == true) {
            final uploadedAvatar = response.data['data']['avatar'] as String?;
            if (uploadedAvatar != null && uploadedAvatar.isNotEmpty) {
              setState(() {
                _avatarController.text = uploadedAvatar;
              });
              await ref.read(authProvider.notifier).checkAuthStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture updated successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              return;
            }
          }
        } catch (_) {
          final base64Image = base64Encode(bytes);
          final mimeType = pickedFile.mimeType ?? 'image/jpeg';
          final dataUrl = 'data:$mimeType;base64,$base64Image';

          setState(() {
            _avatarController.text = dataUrl;
          });
          await _saveProfile();
        }
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('No implementation found')) {
        if (mounted) {
          _showChangeAvatarDialog();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Plugin pending restart. Select a preset avatar or enter an image URL!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final response = await ApiClient().dio.patch(
        '/users/me',
        data: {
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'avatar': _avatarController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        await ref.read(authProvider.notifier).checkAuthStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  LucideIcons.image,
                  color: AppColors.amber500,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.camera,
                  color: AppColors.amber500,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.layoutGrid,
                  color: AppColors.amber500,
                ),
                title: const Text('Choose Preset or URL'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangeAvatarDialog();
                },
              ),
              if (_avatarController.text.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    LucideIcons.trash2,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarController.clear();
                    });
                    _saveProfile();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeAvatarDialog() {
    final tempController = TextEditingController(text: _avatarController.text);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Preset Avatar / Image URL'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preset Avatars:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempController.clear();
                });
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _avatarController.text = tempController.text.trim();
                });
                Navigator.pop(ctx);
                _saveProfile();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl, String userInitials) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 46,
        backgroundColor: AppColors.amber500,
        child: Text(
          userInitials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    final resolved = ApiClient.resolveUrl(avatarUrl);
    if (resolved.startsWith('data:image/')) {
      try {
        final commaIndex = resolved.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = resolved.substring(commaIndex + 1);
          final bytes = base64Decode(base64Str);
          return CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.amber500,
            backgroundImage: MemoryImage(bytes),
          );
        }
      } catch (_) {}
    }

    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        color: AppColors.amber500,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            userInitials,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String count,
    String label,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.ink950 : AppColors.ink100.withAlpha(150),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.ink800 : AppColors.ink200.withAlpha(150),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.amber500),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.ink900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.ink400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final notesState = ref.watch(notesProvider);
    final workspacesState = ref.watch(workspacesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatarUrl = _avatarController.text.isNotEmpty
        ? _avatarController.text
        : user?.avatar;

    final userInitials = (user?.name.isNotEmpty == true)
        ? user!.name
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'WB';

    final totalNotes = notesState.notes.length;
    final totalFavorites = notesState.notes.where((n) => n.isFavorite).length;
    final totalWorkspaces = workspacesState.workspaces.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Hero Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ink900 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.ink800
                          : AppColors.ink200.withAlpha(204),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha(80)
                            : Colors.black.withAlpha(12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar Stack with Camera Badge
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.amber500,
                                    Colors.orangeAccent,
                                  ],
                                ),
                              ),
                              child: _buildAvatarWidget(
                                avatarUrl,
                                userInitials,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber500,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.ink900
                                          : Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(60),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // User Name & Email Badge
                      Text(
                        user?.name.isNotEmpty == true
                            ? user!.name
                            : 'WriteBook User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  LucideIcons.checkCircle2,
                                  size: 11,
                                  color: AppColors.amber500,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amber500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Live User Statistics Cards
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            '$totalNotes',
                            'Notes',
                            LucideIcons.fileText,
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            context,
                            '$totalFavorites',
                            'Favorites',
                            LucideIcons.star,
                          ),
                          const SizedBox(width: 10),
                          _buildStatCard(
                            context,
                            '$totalWorkspaces',
                            'Workspaces',
                            LucideIcons.layoutGrid,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Preset Avatar Row
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'QUICK AVATARS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.ink400,
                    ),
                  ),
                ),

                // Edit Information Section Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.ink900 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.ink800
                          : AppColors.ink200.withAlpha(204),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Input Field
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.ink900,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(LucideIcons.user, size: 18),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.ink950
                              : AppColors.ink100.withAlpha(120),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.ink800
                                  : AppColors.ink200,
                            ),
                          ),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Bio Input Field
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.ink900,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(
                            LucideIcons.fileText,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.ink950
                              : AppColors.ink100.withAlpha(120),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.ink800
                                  : AppColors.ink200,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
