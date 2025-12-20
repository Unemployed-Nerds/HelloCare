import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../screens/patient/report_detail_page.dart';
import '../../widgets/ai_summary_display.dart';

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
  Map<String, dynamic>? _aiSummary;

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
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['reports'] != null) {
          // Process AI summary - handle both string and Map formats
          Map<String, dynamic>? processedSummary;
          final aiSummaryRaw = data['aiSummary'];
          
          if (aiSummaryRaw != null) {
            print('AI Summary Raw Type: ${aiSummaryRaw.runtimeType}');
            print('AI Summary Raw: $aiSummaryRaw');
            
            // Process the data - handle both string and Map formats (same as patient page)
            Map<String, dynamic> processedData;
            
            if (aiSummaryRaw is String) {
              // If data is a string, try to parse it as JSON
              try {
                // Remove markdown code block markers (```) if present
                String jsonString = aiSummaryRaw.trim();
                if (jsonString.startsWith('```')) {
                  // Remove opening ```
                  jsonString = jsonString.substring(3);
                  // Remove language identifier if present (e.g., ```json)
                  final firstNewline = jsonString.indexOf('\n');
                  if (firstNewline != -1) {
                    jsonString = jsonString.substring(firstNewline + 1);
                  }
                  // Remove closing ```
                  if (jsonString.endsWith('```')) {
                    jsonString = jsonString.substring(0, jsonString.length - 3);
                  }
                  jsonString = jsonString.trim();
                }
                
                final decoded = json.decode(jsonString);
                processedData = decoded is Map ? Map<String, dynamic>.from(decoded) : {'overallSummary': aiSummaryRaw};
              } catch (e) {
                print('Failed to parse JSON string: $e');
                // If it's not valid JSON, treat as plain text summary
                processedData = {
                  'overallSummary': aiSummaryRaw,
                  'findings': [],
                  'priorityEmoji': '✅',
                };
              }
            } else if (aiSummaryRaw is Map) {
              processedData = Map<String, dynamic>.from(aiSummaryRaw);
            } else {
              print('Unexpected data type: ${aiSummaryRaw.runtimeType}');
              processedData = {
                'overallSummary': aiSummaryRaw.toString(),
                'findings': [],
                'priorityEmoji': '✅',
              };
            }

            print('Processed data keys: ${processedData.keys.toList()}');

            // Check if it's the new structured format (has findings or overallSummary)
            if (processedData.containsKey('findings') || processedData.containsKey('overallSummary')) {
              // New structured format - normalize all fields
              final findings = processedData['findings'];
              final findingsList = findings is List 
                  ? findings.map((f) => f is Map ? Map<String, dynamic>.from(f) : {}).toList()
                  : [];
              
              processedSummary = {
                'schemaVersion': processedData['schemaVersion']?.toString() ?? 'v1.0',
                'reportId': processedData['reportId'],
                'reportDate': processedData['reportDate']?.toString(),
                'confidence': processedData['confidence'] is num ? processedData['confidence'] : null,
                'confidenceBreakdown': processedData['confidenceBreakdown'] is Map 
                    ? Map<String, dynamic>.from(processedData['confidenceBreakdown'])
                    : processedData['confidenceBreakdown'] != null ? processedData['confidenceBreakdown'] : null,
                'findings': findingsList,
                'identifiedPanels': processedData['identifiedPanels'] is List
                    ? (processedData['identifiedPanels'] as List).map((e) => e.toString()).toList()
                    : [],
                'priorityEmoji': processedData['priorityEmoji']?.toString() ?? '✅',
                'overallSummary': processedData['overallSummary']?.toString() ?? '',
                'criticalSummary': processedData['criticalSummary']?.toString() ?? '',
                'suggestedLifestyleFocus': processedData['suggestedLifestyleFocus'] is List
                    ? (processedData['suggestedLifestyleFocus'] as List).map((e) => e.toString()).toList()
                    : [],
                'educationSearchTerms': processedData['educationSearchTerms'] is List
                    ? (processedData['educationSearchTerms'] as List).map((e) => e.toString()).toList()
                    : [],
                'parsingNotes': processedData['parsingNotes']?.toString() ?? '',
                'phiRedacted': processedData['phiRedacted'] == true,
                'generatedAt': processedData['generatedAt']?.toString(),
                'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : null,
              };
              print('Summary data processed successfully');
            } else if (processedData.containsKey('summary')) {
              // Old format - convert to new format structure
              processedSummary = {
                'overallSummary': processedData['summary']?.toString() ?? '',
                'findings': [],
                'priorityEmoji': '✅',
                'generatedAt': processedData['generatedAt']?.toString(),
                'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : null,
              };
            } else {
              // Fallback: treat as plain text summary
              print('Invalid response format - no findings or summary field, using fallback');
              processedSummary = {
                'overallSummary': processedData['overallSummary']?.toString() ?? processedData.toString(),
                'findings': [],
                'priorityEmoji': '✅',
              };
            }
          }
          
          setState(() {
            _reports = data['reports'] as List<dynamic>?;
            _aiSummary = processedSummary;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        final error = response['error'];
        setState(() {
          _error = (error is Map && error['message'] != null) 
              ? error['message'].toString() 
              : 'Failed to load reports';
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
                  : Column(
                      children: [
                        // AI Summary Section - Using shared widget
                        if (_aiSummary != null && _aiSummary!.isNotEmpty)
                          Expanded(
                            flex: 1,
                            child: AISummaryDisplay(summaryData: _aiSummary!),
                          ),
                        // Reports List
                        Expanded(
                          flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              if (_aiSummary != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    'Reports',
                                      style: TextStyle(
                                      fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reports!.length,
                            itemBuilder: (context, index) {
                              final report = _reports![index];
                              // Safely extract reportDate - handle both string and Map (Timestamp) formats
                              String reportDateStr = '';
                              final reportDate = report['reportDate'];
                              if (reportDate != null) {
                                if (reportDate is String) {
                                  // Already a string, format it nicely
                                  try {
                                    final date = DateTime.parse(reportDate);
                                    reportDateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                  } catch (e) {
                                    reportDateStr = reportDate;
                                  }
                                } else if (reportDate is Map) {
                                  // Firestore Timestamp format - extract seconds
                                  final seconds = reportDate['seconds'] ?? reportDate['_seconds'];
                                  if (seconds != null) {
                                    try {
                                      final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                                      reportDateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                    } catch (e) {
                                      reportDateStr = 'Invalid date';
                                    }
                                  }
                                }
                              }
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(report['title']?.toString() ?? 'Report'),
                                  subtitle: Text(reportDateStr.isEmpty ? 'No date' : reportDateStr),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    final reportId = report['reportId']?.toString();
                                    final storageUrl = report['storageUrl']?.toString();
                                    if (reportId != null && reportId.isNotEmpty) {
                                      // Pass report data and storageUrl for QR code access
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReportDetailPage(
                                            reportId: reportId,
                                            downloadUrl: storageUrl,
                                            reportData: report as Map<String, dynamic>,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

