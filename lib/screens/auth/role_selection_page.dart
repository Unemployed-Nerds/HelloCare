import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medical_services,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome to HelloCare',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select your role to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/patient-login'),
                    icon: const Icon(Icons.person, size: 24),
                    label: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'I am a Patient',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/doctor-login'),
                    icon: const Icon(Icons.medical_information, size: 24),
                    label: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'I am a Doctor',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


