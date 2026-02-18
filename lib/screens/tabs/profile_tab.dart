import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/habit_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_logo.dart';
import '../login_screen.dart';
import '../edit_profile_screen.dart';
import '../notification_settings_screen.dart';
import '../privacy_policy_screen.dart';

class ProfileTab extends StatefulWidget {
  final HabitService habitService;

  const ProfileTab({super.key, required this.habitService});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late bool _darkMode;
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _darkMode = StorageService.darkMode;
    _notifications = StorageService.notifications;
  }

  int _totalStreak() {
    if (widget.habitService.habits.isEmpty) return 0;
    return widget.habitService.habits
        .map((h) => h.currentStreak)
        .reduce(math.max);
  }

  int _totalCompleted() {
    return widget.habitService.habits
        .fold(0, (sum, h) => sum + h.completedDates.length);
  }

  int _totalHabits() {
    return widget.habitService.habits.length;
  }

  String _memberSince() {
    if (widget.habitService.habits.isEmpty) return 'Just joined';
    final earliest = widget.habitService.habits
        .map((h) => h.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Since ${months[earliest.month - 1]} ${earliest.year}';
  }

  void _sendFeedback() {
    final feedbackController = TextEditingController();
    String selectedType = 'General';
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textSecondaryColor(context)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Send Feedback',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Help us improve StreakUp!',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // Feedback type chips
                Wrap(
                  spacing: 8,
                  children: ['General', 'Bug', 'Feature', 'Other'].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : AppTheme.background(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondaryColor(context)
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondaryColor(context),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Feedback text field
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us what you think...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondaryColor(context)
                          .withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: AppTheme.background(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),

                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            final text = feedbackController.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      const Text('Please write your feedback'),
                                  backgroundColor: AppTheme.accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                              return;
                            }

                            setSheetState(() => isSending = true);

                            try {
                              final user = AuthService.currentUser;
                              await FirebaseFirestore.instance
                                  .collection('feedback')
                                  .add({
                                'message': text,
                                'type': selectedType,
                                'userId': user?.uid ?? 'anonymous',
                                'userEmail': user?.email ??
                                    (StorageService.userEmail.isNotEmpty
                                        ? StorageService.userEmail
                                        : 'unknown'),
                                'platform': Platform.operatingSystem,
                                'appVersion': '1.0.0',
                                'createdAt': FieldValue.serverTimestamp(),
                              }).timeout(const Duration(seconds: 10));

                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Thank you for your feedback!'),
                                    backgroundColor: AppTheme.primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => isSending = false);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to send: ${e.toString().contains('permission') ? 'Permission denied. Check Firestore rules.' : 'Please try again.'}'),
                                    backgroundColor: AppTheme.accentColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Send Feedback',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?.displayName ?? StorageService.userName;
    final email = user?.email ?? StorageService.userEmail;
    final savedPhoto = StorageService.profilePhotoPath;
    final photoUrl = user?.photoURL ??
        (savedPhoto.isNotEmpty ? savedPhoto : null);

    return ListenableBuilder(
      listenable: widget.habitService,
      builder: (context, _) {
        final streak = _totalStreak();
        final completed = _totalCompleted();
        final totalHabits = _totalHabits();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Profile',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Profile card
              _buildProfileCard(name, email, photoUrl),
              const SizedBox(height: 16),

              // Stats row
              _buildStatsRow(streak, completed, totalHabits),
              const SizedBox(height: 24),

              // Settings section
              _buildSectionLabel('Preferences'),
              const SizedBox(height: 12),

              _buildToggleItem(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: _darkMode ? 'Use Light Theme' : 'Use Dark Theme',
                value: _darkMode,
                color: const Color(0xFF6C63FF),
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  StorageService.setDarkMode(val);
                  themeNotifier.value =
                      val ? ThemeMode.dark : ThemeMode.light;
                  SystemChrome.setSystemUIOverlayStyle(
                    SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness:
                          val ? Brightness.light : Brightness.dark,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildToggleItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Habit reminders',
                value: _notifications,
                color: const Color(0xFFFFB74D),
                onChanged: (val) async {
                  setState(() => _notifications = val);
                  await StorageService.setNotifications(val);
                  if (val) {
                    await NotificationService.rescheduleAll(
                        widget.habitService.habits);
                  } else {
                    await NotificationService.cancelAll();
                  }
                },
              ),

              const SizedBox(height: 24),

              // General section
              _buildSectionLabel('General'),
              const SizedBox(height: 12),

              _buildSettingsItem(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                color: const Color(0xFF42A5F5),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  );
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                color: const Color(0xFFFFB74D),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationSettingsScreen(
                          habitService: widget.habitService),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                icon: Icons.mail_outline_rounded,
                title: 'Send Feedback',
                color: const Color(0xFF42A5F5),
                onTap: _sendFeedback,
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                color: const Color(0xFF78909C),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'About StreakUp',
                color: const Color(0xFF00C9A7),
                onTap: () => _showAbout(context),
              ),

              const SizedBox(height: 8),

              // Sign out as a list tile
              _buildSignOutItem(),

              const SizedBox(height: 16),

              // App version
              Center(
                child: Text(
                  'StreakUp v1.0.0',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignOutItem() {
    return GestureDetector(
      onTap: () => _handleSignOut(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.cardBorderColor(context),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.logout_rounded, color: AppTheme.accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.accentColor.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, String? photoUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.12),
            AppTheme.surface(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.background(context),
            backgroundImage: photoUrl != null
                ? (photoUrl.startsWith('http')
                    ? NetworkImage(photoUrl) as ImageProvider
                    : (File(photoUrl).existsSync()
                        ? FileImage(File(photoUrl))
                        : null))
                : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'User',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _memberSince(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int streak, int completed, int totalHabits) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            Icons.local_fire_department_rounded,
            '$streak',
            'Streak',
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStat(
            Icons.check_circle_rounded,
            '$completed',
            'Completed',
            const Color(0xFF00C9A7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniStat(
            Icons.list_rounded,
            '$totalHabits',
            'Habits',
            const Color(0xFF6C63FF),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
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

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.35),
            inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.textSecondaryColor(context)
                : const Color(0xFF999999),
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.15)
                : const Color(0xFFCCCCCC),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.cardBorderColor(context),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondaryColor(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 10),
            Text('StreakUp',
                style: TextStyle(color: AppTheme.textPrimaryColor(context))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build Better Habits, One Streak at a Time.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: TextStyle(color: AppTheme.textPrimaryColor(context))),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondaryColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out',
                style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
