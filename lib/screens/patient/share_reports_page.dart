import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/qr_code_display.dart';

class ShareReportsPage extends StatefulWidget {
  const ShareReportsPage({super.key});

  @override
  State<ShareReportsPage> createState() => _ShareReportsPageState();
}

class _ShareReportsPageState extends State<ShareReportsPage> {
  final ApiService _apiService = ApiService();
  final Set<String> _selectedReportIds = {};
  String? _qrToken;
  bool _isGenerating = false;

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

  Future<void> _generateQRCode() async {
    if (_selectedReportIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one report')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await _apiService.generateQRCode(
        reportIds: _selectedReportIds.toList(),
      );
      if (response['success']) {
        setState(() {
          _qrToken = response['data']['qrToken'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Share Reports'),
      ),
      body: _qrToken != null
          ? QRCodeDisplay(qrToken: _qrToken!)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _selectedReportIds.isEmpty || _isGenerating
                        ? null
                        : _generateQRCode,
                    child: _isGenerating
                        ? const CircularProgressIndicator()
                        : const Text('Generate QR Code'),
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

