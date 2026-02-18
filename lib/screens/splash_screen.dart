import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Widget destination;

    if (StorageService.isFirstTime) {
      destination = const OnboardingScreen();
    } else if (!StorageService.isLoggedIn) {
      destination = const LoginScreen();
    } else if (!AuthService.isSignedIn) {
      // SharedPreferences says logged in, but Firebase Auth session expired
      // (e.g. after APK update with different signing key)
      // Clear stale local state and send user to login
      await StorageService.setLoggedIn(false);
      await StorageService.setUserName('');
      await StorageService.setUserEmail('');
      await StorageService.setSignInMethod('');
      destination = const LoginScreen();
    } else {
      destination = const DashboardScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const AppLogo(size: 120),
              const SizedBox(height: 30),

              // App Name
              Text(
                'StreakUp',
                style: AppTheme.appNameStyle.copyWith(
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Build Better Habits',
                style: AppTheme.taglineStyle.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor.withValues(alpha: 0.7),
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
