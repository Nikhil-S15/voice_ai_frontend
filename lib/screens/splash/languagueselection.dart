import 'package:flutter/material.dart';
import 'package:voice_ai_app/screens/onboarding/onboarding_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  void _navigateToOnboarding(BuildContext context, String language) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingPage(selectedLanguage: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Voice Bio Marker India",
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo implementation - update the path to match where you place the image in your assets
              Image.asset(
                'assets/image/ChatGPT Image Sep 4, 2025 at 10_53_22 PM.png', // Update this path
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback widget if image fails to load
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic, size: 80, color: AppColors.primary),
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                "Select Language",
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 70,
                child: ElevatedButton(
                  onPressed: () => _navigateToOnboarding(context, 'en'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "English",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 70,
                child: ElevatedButton(
                  onPressed: () => _navigateToOnboarding(context, 'ml'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "മലയാളം",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
