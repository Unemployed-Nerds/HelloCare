import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/pdf_viewer.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Report will be loaded via provider
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return FutureBuilder(
      future: reportProvider.getReport(widget.reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: Text('Report not found')),
          );
        }

        final report = snapshot.data!;

        return Scaffold(
          backgroundColor: AppTheme.backgroundGreen,
          appBar: AppBar(
            title: Text(report.title),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (report.category != null)
                          Text('Category: ${report.category}'),
                        if (report.doctorName != null)
                          Text('Doctor: ${report.doctorName}'),
                        if (report.clinicName != null)
                          Text('Clinic: ${report.clinicName}'),
                        Text('Report Date: ${report.reportDate.toString().split(' ')[0]}'),
                        Text('Uploaded: ${report.uploadDate.toString().split(' ')[0]}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (report.fileType == 'pdf')
                  SizedBox(
                    height: 600,
                    child: PDFViewer(url: report.s3Url ?? ''),
                  )
                else
                  Image.network(
                    report.s3Url ?? '',
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Failed to load image'),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}


