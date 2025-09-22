// Splash Screen Page

import 'package:flutter/material.dart';
// import 'package:voice_ai_app/screens/onboarding/onboarding_page.dart';
import 'package:voice_ai_app/screens/splash/languagueselection.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://media.licdn.com/dms/image/v2/C561BAQG6DfFNV0Ijww/company-background_10000/company-background_10000/0/1612435701592/amritahospitals_cover?e=2147483647&v=beta&t=yr5b5kx0DBvAO5TqRbUqHDZ_Sq1oqeWyhhsLyTmNXlI',
            fit: BoxFit.cover,
          ),

          // Overlay to darken background
          // ignore: deprecated_member_use
          Container(color: Colors.black.withOpacity(0.6)),

          // Foreground content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to Amrita Hospital',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Expert care with modern technology.\n'
                    'Your health is our priority.\n'
                    'Trusted by millions.\n\n'
                    '1300+ Beds | 10M+ Patients | 128+ Equipments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionPage(),
                        ),
                      );
                    },
                    child: const Text('Next', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
