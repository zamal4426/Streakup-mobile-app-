import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _hasChanges = false;
  bool _uploadingPhoto = false;
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    final name = user?.displayName ?? StorageService.userName;
    _nameController.text = name;
    final savedPath = StorageService.profilePhotoPath;
    if (savedPath.isNotEmpty) _localPhotoPath = savedPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor(context)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded,
                    color: AppTheme.primaryColor),
                title: Text('Take Photo',
                    style:
                        TextStyle(color: AppTheme.textPrimaryColor(context))),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded,
                    color: AppTheme.primaryColor),
                title: Text('Choose from Gallery',
                    style:
                        TextStyle(color: AppTheme.textPrimaryColor(context))),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final file = await AuthService.pickImage(source);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final result = await AuthService.uploadProfilePhoto(file);
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _localPhotoPath = result;
          _hasChanges = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name cannot be empty'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    await AuthService.updateDisplayName(name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final email = user?.email ?? StorageService.userEmail;
    final photoUrl = user?.photoURL;
    final currentName =
        user?.displayName ?? StorageService.userName;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: AppTheme.surface(context),
                            backgroundImage: _buildAvatarImage(photoUrl),
                            child: _uploadingPhoto
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  )
                                : (_localPhotoPath == null && photoUrl == null
                                    ? Text(
                                        currentName.isNotEmpty
                                            ? currentName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                        ),
                                      )
                                    : null),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadingPhoto ? null : _pickProfilePhoto,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.background(context), width: 3),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    _buildFieldLabel('Display Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style:
                          TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 16),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _hasChanges = true),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(
                            color:
                                AppTheme.textSecondaryColor(context).withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: AppTheme.surface(context),
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppTheme.textSecondaryColor(context), size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppTheme.cardBorderColor(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email (read-only)
                    _buildFieldLabel('Email'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined,
                              color: AppTheme.textSecondaryColor(context), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email.isNotEmpty ? email : 'Not available',
                              style: TextStyle(
                                color: email.isNotEmpty
                                    ? AppTheme.textSecondaryColor(context)
                                    : AppTheme.textSecondaryColor(context)
                                        .withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (email.isNotEmpty)
                            Icon(Icons.lock_outline_rounded,
                                color: AppTheme.textSecondaryColor(context)
                                    .withValues(alpha: 0.3),
                                size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Email cannot be changed here',
                        style: TextStyle(
                          color:
                              AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Account info
                    _buildFieldLabel('Account'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppTheme.cardBorderColor(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.login_rounded,
                            'Sign-in method',
                            StorageService.signInMethod.isNotEmpty
                                ? StorageService.signInMethod
                                : (user != null ? 'Google' : 'Local'),
                          ),
                          Divider(
                            color: AppTheme.cardBorderColor(context),
                            height: 20,
                          ),
                          _buildInfoRow(
                            Icons.verified_user_outlined,
                            'Account status',
                            'Active',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _hasChanges ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.surface(context),
                          disabledForegroundColor:
                              AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _buildAvatarImage(String? photoUrl) {
    if (_localPhotoPath != null && _localPhotoPath!.isNotEmpty) {
      if (_localPhotoPath!.startsWith('http')) {
        return NetworkImage(_localPhotoPath!);
      }
      final file = File(_localPhotoPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    if (photoUrl != null && photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }
    return null;
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimaryColor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Edit Profile',
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSecondaryColor(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondaryColor(context), size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimaryColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
