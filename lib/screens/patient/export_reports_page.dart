import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class ExportReportsPage extends StatefulWidget {
  const ExportReportsPage({super.key});

  @override
  State<ExportReportsPage> createState() => _ExportReportsPageState();
}

class _ExportReportsPageState extends State<ExportReportsPage> {
  final ApiService _apiService = ApiService();
  final Set<String> _selectedReportIds = {};
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        reportProvider.loadReports(userProvider.currentUser!.userId);
      }
    });
  }

  Future<void> _exportReports() async {
    if (_selectedReportIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one report')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final response = await _apiService.exportReports(
        reportIds: _selectedReportIds.toList(),
      );
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export link generated. Check your email or download from the link.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedReportIds.isEmpty || _isExporting
                  ? null
                  : _exportReports,
              child: _isExporting
                  ? const CircularProgressIndicator()
                  : const Text('Export Selected Reports'),
            ),
          ),
          Expanded(
            child: reportProvider.reports.isEmpty
                ? const Center(child: Text('No reports available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reportProvider.reports.length,
                    itemBuilder: (context, index) {
                      final report = reportProvider.reports[index];
                      final isSelected = _selectedReportIds.contains(report.reportId);
                      return CheckboxListTile(
                        title: Text(report.title),
                        subtitle: Text(report.category ?? ''),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedReportIds.add(report.reportId);
                            } else {
                              _selectedReportIds.remove(report.reportId);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


