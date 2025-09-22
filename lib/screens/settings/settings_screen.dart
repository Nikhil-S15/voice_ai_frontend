import 'package:flutter/material.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Information
          Card(
            child: ListTile(
              leading: const Icon(Icons.info, color: AppColors.primary),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
              onTap: () {
                // You can add version tap counter for hidden admin access here
              },
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Policy
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppColors.primary),
              title: const Text('Privacy Policy'),
              onTap: () {
                // Navigate to privacy policy
              },
            ),
          ),
          const SizedBox(height: 16),

          // Terms of Service
          Card(
            child: ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: const Text('Terms of Service'),
              onTap: () {
                // Navigate to terms of service
              },
            ),
          ),
          const SizedBox(height: 16),

          // Admin Access (Hidden behind long press)
          GestureDetector(
            onLongPress: () {
              _showAdminAccessDialog(context);
            },
            child: Card(
              child: const ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.grey),
                title: Text(
                  'Admin Portal',
                  style: TextStyle(color: Colors.grey),
                ),
                subtitle: Text('Long press to access'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access'),
        content: const Text('Enter admin credentials to continue'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-login');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
