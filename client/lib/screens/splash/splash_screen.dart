import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Background wave animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Logo scale animation with elastic curve
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Logo fade animation
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Logo slide animation
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Shimmer animation
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Wait a bit before starting
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Check auth status
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating particles
          _buildFloatingParticles(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                _buildAnimatedLogo(),

                const SizedBox(height: 24),

                // Tagline with fade in
                _buildTagline(),
              ],
            ),
          ),

          // Bottom loading indicator
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primaryTeal.withValues(alpha: 0.8),
                AppColors.primaryDark,
              ],
              stops: [
                0.0,
                0.5 + 0.2 * math.sin(_backgroundController.value * 2 * math.pi),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ParticlePainter(
            animation: _backgroundController.value,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _pulseController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _logoSlideAnimation,
          child: FadeTransition(
            opacity: _logoFadeAnimation,
            child: Transform.scale(
              scale: _logoScaleAnimation.value * _pulseAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow effect
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.ctaBlue.withValues(alpha: 0.3),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // App icon
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _logoController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );

        return Opacity(
          opacity: taglineOpacity.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - taglineOpacity.value)),
            child: Text(
              'Your Digital Experience',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          final indicatorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _logoController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ),
          );

          return Opacity(
            opacity: indicatorOpacity.value,
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.ctaBlue,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for floating particles
class ParticlePainter extends CustomPainter {
  final double animation;
  final int particleCount = 50;

  ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    for (int i = 0; i < particleCount; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final speed = random.nextDouble() * 0.5 + 0.5;
      final phase = random.nextDouble() * 2 * math.pi;

      final x = baseX + math.sin(animation * 2 * math.pi * speed + phase) * 30;
      final y = baseY + math.cos(animation * 2 * math.pi * speed + phase) * 30;

      final opacity = (0.1 + 0.1 * math.sin(animation * 2 * math.pi + phase))
          .clamp(0.0, 1.0);
      paint.color = AppColors.white.withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
