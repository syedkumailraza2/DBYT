import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme.dart';
import 'core/providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/profile/edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await SharedPreferences.getInstance();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => createAuthProvider(),
      child: const DBYTApp(),
    ),
  );
}

class DBYTApp extends StatelessWidget {
  const DBYTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DBYT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildPageRoute(
          const SplashScreen(),
          settings,
          transitionType: TransitionType.fade,
        );
      case '/login':
        return _buildPageRoute(
          const LoginScreen(),
          settings,
          transitionType: TransitionType.slideUp,
        );
      case '/register':
        return _buildPageRoute(
          const RegisterScreen(),
          settings,
          transitionType: TransitionType.slideRight,
        );
      case '/home':
        return _buildPageRoute(
          const MainScreen(),
          settings,
          transitionType: TransitionType.fade,
        );
      case '/edit-profile':
        return _buildPageRoute(
          const EditProfileScreen(),
          settings,
          transitionType: TransitionType.slideRight,
        );
      default:
        return _buildPageRoute(
          const SplashScreen(),
          settings,
          transitionType: TransitionType.fade,
        );
    }
  }

  PageRoute _buildPageRoute(
    Widget page,
    RouteSettings settings, {
    TransitionType transitionType = TransitionType.fade,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case TransitionType.fade:
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          case TransitionType.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeIn,
                ),
                child: child,
              ),
            );
          case TransitionType.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            );
        }
      },
    );
  }
}

enum TransitionType { fade, slideUp, slideRight }
