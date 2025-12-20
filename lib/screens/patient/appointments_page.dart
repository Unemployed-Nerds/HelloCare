import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/voice_assistant_provider.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/voice_assistant_widget.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final voiceProvider = Provider.of<VoiceAssistantProvider>(context);
    final currentUser = userProvider.currentUser;

    // Handle case where user data hasn't loaded yet
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        appBar: AppBar(
          title: const Text('My Appointments'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('My Appointments'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: !voiceProvider.isListening && !voiceProvider.isProcessing && !voiceProvider.waitingForFollowUp,
            enableDrag: !voiceProvider.isListening && !voiceProvider.isProcessing && !voiceProvider.waitingForFollowUp,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return const VoiceAssistantWidget();
              },
            ),
          );
        },
        label: Text(
          voiceProvider.isListening
              ? 'Listening...'
              : voiceProvider.isProcessing
                  ? 'Working...'
                  : voiceProvider.isSpeaking
                      ? 'Speaking...'
                      : 'Voice Assistant',
        ),
        icon: Icon(
          voiceProvider.isListening
              ? Icons.hearing
              : voiceProvider.isProcessing
                  ? Icons.hourglass_empty
                  : voiceProvider.isSpeaking
                      ? Icons.volume_up
                      : Icons.mic,
        ),
      ),
      body: StreamBuilder(
        stream: appointmentProvider.getPatientAppointmentsStream(
          currentUser.userId,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 64, color: AppTheme.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No appointments yet',
                    style: TextStyle(fontSize: 18, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/patient/book-appointment'),
                    child: const Text('Book an Appointment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AppointmentCard(
                appointment: appointment,
                isPatientView: true,
              );
            },
          );
        },
      ),
    );
  }
}

