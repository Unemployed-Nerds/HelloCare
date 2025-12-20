import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/user_provider.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  const DoctorAvailabilityPage({super.key});

  @override
  State<DoctorAvailabilityPage> createState() => _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState extends State<DoctorAvailabilityPage> {
  final Map<String, Map<String, dynamic>> _availability = {
    'monday': {'start': '09:00', 'end': '17:00', 'available': true},
    'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
    'friday': {'start': '09:00', 'end': '17:00', 'available': true},
    'saturday': {'start': null, 'end': null, 'available': false},
    'sunday': {'start': null, 'end': null, 'available': false},
  };

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Manage Availability'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._availability.entries.map((entry) {
            final day = entry.key;
            final schedule = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(day[0].toUpperCase() + day.substring(1)),
                subtitle: schedule['available'] == true
                    ? Text('${schedule['start']} - ${schedule['end']}')
                    : const Text('Not available'),
                trailing: Switch(
                  value: schedule['available'] == true,
                  onChanged: (value) {
                    setState(() {
                      _availability[day] = {
                        'start': value ? '09:00' : null,
                        'end': value ? '17:00' : null,
                        'available': value,
                      };
                    });
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final currentUser = userProvider.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User data not loaded. Please try again.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              final success = await doctorProvider.updateAvailability(
                doctorId: currentUser.userId,
                availability: _availability,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Availability updated successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Save Availability'),
            ),
          ),
        ],
      ),
    );
  }
}

