import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/user_provider.dart';

class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Doctor Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'D',
                  style: const TextStyle(fontSize: 40, color: AppTheme.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${user?.name ?? ''}'),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? ''}'),
                    const SizedBox(height: 8),
                    if (user?.phone != null) Text('Phone: ${user!.phone}'),
                    if (user?.specialization != null)
                      Text('Specialization: ${user!.specialization}'),
                    if (user?.yearsOfExperience != null)
                      Text('Experience: ${user!.yearsOfExperience} years'),
                    if (user?.bio != null) ...[
                      const SizedBox(height: 8),
                      Text('Bio: ${user!.bio}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


