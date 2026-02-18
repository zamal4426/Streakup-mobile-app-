import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
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
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDate(context),
                    const SizedBox(height: 20),
                    _buildSection(context, 'Introduction',
                        'StreakUp ("we", "our", or "us") is a habit tracking application designed to help you build better habits. This Privacy Policy explains how we collect, use, and protect your information when you use our app.'),
                    _buildSection(context, 'Information We Collect',
                        'Account Information: When you create an account, we collect your name, email address, and profile photo (if provided).\n\n'
                        'Habit Data: We store the habits you create, including names, schedules, completion records, streaks, and notes.\n\n'
                        'Device Information: We may collect device type and operating system version for app compatibility purposes.'),
                    _buildSection(context, 'How We Use Your Information',
                        'We use your information to:\n\n'
                        '- Provide and maintain the StreakUp service\n'
                        '- Sync your habit data across devices\n'
                        '- Send you reminders and notifications you have configured\n'
                        '- Improve and optimize the app experience'),
                    _buildSection(context, 'Data Storage & Security',
                        'Your data is stored securely using Google Firebase services. We use industry-standard security measures including encryption in transit and at rest to protect your personal information.\n\n'
                        'Your habit data is synced to the cloud to enable cross-device access. Local data is also stored on your device for offline functionality.'),
                    _buildSection(context, 'Third-Party Services',
                        'We use the following third-party services:\n\n'
                        '- Google Firebase (Authentication, Cloud Firestore, Cloud Storage) for account management and data storage\n'
                        '- Google Sign-In for authentication\n\n'
                        'These services have their own privacy policies governing the use of your information.'),
                    _buildSection(context, 'Notifications & Alarms',
                        'StreakUp uses local notifications and alarms to remind you about your habits. These are configured by you and processed entirely on your device. No notification data is sent to external servers.'),
                    _buildSection(context, 'Data Retention',
                        'Your data is retained as long as your account is active. You can delete your account and all associated data at any time by contacting us.'),
                    _buildSection(context, 'Your Rights',
                        'You have the right to:\n\n'
                        '- Access your personal data\n'
                        '- Correct inaccurate data\n'
                        '- Delete your account and data\n'
                        '- Export your data\n'
                        '- Opt out of non-essential communications'),
                    _buildSection(context, 'Children\'s Privacy',
                        'StreakUp is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.'),
                    _buildSection(context, 'Changes to This Policy',
                        'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the app.'),
                    _buildSection(context, 'Contact Us',
                        'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                        'Email: streakupmail@gmail.com'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDate(BuildContext context) {
    return Text(
      'Last updated: February 15, 2026',
      style: TextStyle(
        color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.6),
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
