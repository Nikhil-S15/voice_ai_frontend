import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_page.dart';
import '../screens/splash/languagueselection.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/settings/settings_screen.dart'; // Add this import

class AppRoutes {
  static final routes = <String, WidgetBuilder>{
    '/': (context) => const SplashScreen(),
    '/language-selection': (context) => const LanguageSelectionPage(),
    '/settings': (context) => const SettingsScreen(), // Add settings route
    // ✅ Onboarding route expecting selectedLanguage as argument
    '/onboarding': (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> &&
          args.containsKey('selectedLanguage')) {
        return OnboardingPage(selectedLanguage: args['selectedLanguage']);
      } else {
        return const Scaffold(
          body: Center(child: Text("Missing selectedLanguage parameter")),
        );
      }
    },

    // // Admin routes
    '/admin-login': (context) => const AdminLoginScreen(),
    '/admin-dashboard': (context) => const EnhancedAdminDashboardScreen(),
  };
}
