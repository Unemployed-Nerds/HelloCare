import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class ViewPatientReportsPage extends StatefulWidget {
  final String? qrToken;

  const ViewPatientReportsPage({super.key, this.qrToken});

  @override
  State<ViewPatientReportsPage> createState() => _ViewPatientReportsPageState();
}

class _ViewPatientReportsPageState extends State<ViewPatientReportsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic>? _reports;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.qrToken != null) {
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getReportsByQRToken(widget.qrToken!);
      if (response['success']) {
        setState(() {
          _reports = response['data']['reports'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?['message'] ?? 'Failed to load reports';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Patient Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reports == null || _reports!.isEmpty
                  ? const Center(child: Text('No reports available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports!.length,
                      itemBuilder: (context, index) {
                        final report = _reports![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(report['title'] ?? 'Report'),
                            subtitle: Text(report['reportDate'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to report detail
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

