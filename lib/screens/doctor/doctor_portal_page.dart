import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/user_provider.dart';

class DoctorPortalPage extends StatelessWidget {
  const DoctorPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Doctor Portal'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information, size: 48, color: AppTheme.white),
                  const SizedBox(height: 8),
                  Text(
                    userProvider.currentUser?.name ?? 'Doctor',
                    style: const TextStyle(color: AppTheme.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appointments'),
              onTap: () => context.go('/doctor/appointments'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Availability'),
              onTap: () => context.go('/doctor/availability'),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () => context.go('/doctor/scan-qr'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => context.go('/doctor/profile'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await userProvider.signOut();
                if (context.mounted) {
                  context.go('/role-selection');
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_information, size: 100, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Doctor Portal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => context.go('/doctor/appointments'),
              icon: const Icon(Icons.calendar_today),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('View Appointments'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/doctor/scan-qr'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Scan QR Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


