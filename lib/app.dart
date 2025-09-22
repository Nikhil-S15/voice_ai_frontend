// APP DART FILE

import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

class VoiceAIApp extends StatelessWidget {
  const VoiceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice AI App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}
