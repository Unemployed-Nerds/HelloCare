import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/ai_summary_display.dart';
import '../../widgets/report_selection_widget.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';

enum AISummaryViewState {
  selection,
  loading,
  summary,
  error,
}

class AISummaryPage extends StatefulWidget {
  const AISummaryPage({super.key});

  @override
  State<AISummaryPage> createState() => _AISummaryPageState();
}

class _AISummaryPageState extends State<AISummaryPage> {
  final ApiService _apiService = ApiService();
  AISummaryViewState _viewState = AISummaryViewState.selection;
  Map<String, dynamic>? _summaryData;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer loading reports until after the build phase completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReports();
      }
    });
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      await reportProvider.loadReports(userProvider.currentUser!.userId);
    }
  }

  Future<void> _generateSummary(List<String> reportIds) async {
    setState(() {
      _viewState = AISummaryViewState.loading;
      _error = null;
    });

    try {
      final response = await _apiService.getAISummaryForReports(reportIds);
      print('AI Summary Response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('AI Summary Data type: ${data.runtimeType}');
        print('AI Summary Data: $data');
        
        // Process the data - handle both string and Map formats
        Map<String, dynamic> processedData;
        
        if (data is Map) {
          // Check if there's a 'summary' field that contains markdown-wrapped JSON
          if (data.containsKey('summary') && data['summary'] is String) {
            String summaryString = data['summary'] as String;
            print('Found summary field as string, extracting JSON...');
            
            // Remove markdown code blocks (```json ... ``` or ``` ... ```)
            String cleanedData = summaryString;
            final codeBlockPattern = RegExp(r'```[a-zA-Z]*\n?([\s\S]*?)```');
            final match = codeBlockPattern.firstMatch(summaryString);
            if (match != null) {
              cleanedData = match.group(1)?.trim() ?? summaryString;
              print('Extracted JSON from markdown code block');
            }
            
            // Try to parse the JSON from the summary field
            try {
              final decoded = json.decode(cleanedData);
              if (decoded is Map) {
                processedData = Map<String, dynamic>.from(decoded);
                // Merge with other fields from the response (like generatedAt, reportCount)
                processedData.addAll({
                  'generatedAt': data['generatedAt'],
                  'reportCount': data['reportCount'],
                  'lastReportDate': data['lastReportDate'],
                });
                print('Successfully parsed JSON from summary field');
              } else {
                processedData = {
                  'overallSummary': cleanedData,
                  'findings': [],
                  'priorityEmoji': '✅',
                  'generatedAt': data['generatedAt'],
                  'reportCount': data['reportCount'],
                };
              }
            } catch (e) {
              print('Failed to parse JSON from summary field: $e');
              // If it's not valid JSON, treat as plain text summary (strip markdown)
              final strippedData = cleanedData
                  .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove any remaining code blocks
                  .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Remove inline code
                  .trim();
              processedData = {
                'overallSummary': strippedData,
                'findings': [],
                'priorityEmoji': '✅',
                'generatedAt': data['generatedAt'],
                'reportCount': data['reportCount'],
              };
            }
          } else {
            // No summary field, use the data map directly
            processedData = Map<String, dynamic>.from(data);
          }
        } else if (data is String) {
          // If data is a string, check if it contains markdown code blocks
          String cleanedData = data;
          
          // Remove markdown code blocks (```json ... ``` or ``` ... ```)
          final codeBlockPattern = RegExp(r'```[a-zA-Z]*\n?([\s\S]*?)```');
          final match = codeBlockPattern.firstMatch(data);
          if (match != null) {
            cleanedData = match.group(1)?.trim() ?? data;
            print('Extracted JSON from markdown code block');
          }
          
          // Try to parse it as JSON
          try {
            final decoded = json.decode(cleanedData);
            processedData = decoded is Map ? Map<String, dynamic>.from(decoded) : {'overallSummary': cleanedData};
          } catch (e) {
            print('Failed to parse JSON string: $e');
            // If it's not valid JSON, treat as plain text summary (strip markdown)
            final strippedData = cleanedData
                .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove any remaining code blocks
                .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Remove inline code
                .trim();
            processedData = {
              'overallSummary': strippedData,
              'findings': [],
              'priorityEmoji': '✅',
            };
          }
        } else {
          print('Unexpected data type: ${data.runtimeType}');
          throw Exception('Unexpected data type: ${data.runtimeType}');
        }

        print('Processed data keys: ${processedData.keys.toList()}');

        // Check if it's the new structured format (has findings or overallSummary)
        if (processedData.containsKey('findings') || processedData.containsKey('overallSummary')) {
          // New structured format - normalize all fields
          final findings = processedData['findings'];
          final findingsList = findings is List 
              ? findings.map((f) => f is Map ? Map<String, dynamic>.from(f) : {}).toList()
              : [];
          
          setState(() {
            _summaryData = {
              'schemaVersion': processedData['schemaVersion']?.toString() ?? 'v1.0',
              'reportId': processedData['reportId'],
              'reportDate': processedData['reportDate']?.toString(),
              'confidence': processedData['confidence'] is num ? processedData['confidence'] : 0.0,
              'confidenceBreakdown': processedData['confidenceBreakdown'] is Map 
                  ? Map<String, dynamic>.from(processedData['confidenceBreakdown'])
                  : {
                      'legibility': 0.0,
                      'valueParsing': 0.0,
                      'rangeParsing': 0.0,
                      'unitParsing': 0.0,
                      'mappingToTestName': 0.0,
                    },
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
              'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : reportIds.length,
            };
            _viewState = AISummaryViewState.summary;
          });
          print('Summary data set successfully');
        } else if (processedData.containsKey('summary')) {
          // Old format - convert to new format structure
          setState(() {
            _summaryData = {
              'overallSummary': processedData['summary']?.toString() ?? '',
              'findings': [],
              'priorityEmoji': '✅',
              'generatedAt': processedData['generatedAt']?.toString(),
              'reportCount': processedData['reportCount'] is num ? processedData['reportCount'] : reportIds.length,
            };
            _viewState = AISummaryViewState.summary;
          });
        } else {
          // Fallback: try to extract any meaningful data from the response
          print('Invalid response format - no findings or summary field');
          print('Available keys in processedData: ${processedData.keys.toList()}');
          
          // Try to find any text content that might be a summary
          String? fallbackSummary;
          for (var key in processedData.keys) {
            final value = processedData[key];
            if (value is String && value.isNotEmpty && value.length > 20) {
              fallbackSummary = value;
              break;
            }
          }
          
          setState(() {
            _summaryData = {
              'overallSummary': fallbackSummary ?? 'No summary data available. Please try refreshing.',
              'findings': [],
              'priorityEmoji': '✅',
              'reportCount': reportIds.length,
            };
            _viewState = AISummaryViewState.summary;
          });
        }
      } else {
        setState(() {
          _error = response['error']?['message']?.toString() ?? 'Failed to load summary';
          _viewState = AISummaryViewState.error;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading AI summary: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _viewState = AISummaryViewState.error;
      });
    }
  }

  void _goBackToSelection() {
    setState(() {
      _viewState = AISummaryViewState.selection;
      _summaryData = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_viewState == AISummaryViewState.selection) {
      return Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          return ReportSelectionWidget(
            reports: reportProvider.reports,
            onGenerateSummary: _generateSummary,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('AI Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToSelection,
        ),
        actions: [
          if (_viewState == AISummaryViewState.summary)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _goBackToSelection(),
              tooltip: 'Select Different Reports',
            ),
        ],
      ),
      body: _viewState == AISummaryViewState.loading
          ? const Center(child: CircularProgressIndicator())
          : _viewState == AISummaryViewState.error
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'An error occurred',
                        style: const TextStyle(color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _goBackToSelection,
                        child: const Text('Select Reports Again'),
                      ),
                    ],
                  ),
                )
              : _summaryData == null
                  ? const Center(child: Text('No summary data available'))
                  : AISummaryDisplay(summaryData: _summaryData!),
    );
  }
}
