import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/report.dart';
import 'package:intl/intl.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Icon(
            report.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
            color: AppTheme.white,
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.category != null) Text('Category: ${report.category}'),
            if (report.doctorName != null) Text('Doctor: ${report.doctorName}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(report.reportDate)}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}


