import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/appointment_card.dart';

class DoctorAppointmentsPage extends StatelessWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      body: StreamBuilder(
        stream: appointmentProvider.getDoctorAppointmentsStream(
          userProvider.currentUser!.userId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No appointments scheduled'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AppointmentCard(
                appointment: appointment,
                isPatientView: false,
              );
            },
          );
        },
      ),
    );
  }
}


