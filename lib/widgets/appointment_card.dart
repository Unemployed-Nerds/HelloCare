import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isPatientView;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isPatientView = true,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.primaryGreen;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return AppTheme.grey;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(appointment.status),
          child: const Icon(Icons.calendar_today, color: Colors.white),
        ),
        title: Text(
          isPatientView ? appointment.doctorName : appointment.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${DateFormat('MMM dd, yyyy').format(appointment.date)} at ${appointment.time}'),
            if (appointment.doctorSpecialization != null)
              Text('Specialization: ${appointment.doctorSpecialization}'),
            Chip(
              label: Text(
                appointment.status.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _getStatusColor(appointment.status),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}


