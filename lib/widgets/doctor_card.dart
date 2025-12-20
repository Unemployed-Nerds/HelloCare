import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Text(
            doctor.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: AppTheme.white),
          ),
        ),
        title: Text(
          doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialization),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${doctor.rating} (${doctor.reviewCount} reviews)'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}


