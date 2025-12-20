import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class AISummaryPage extends StatefulWidget {
  const AISummaryPage({super.key});

  @override
  State<AISummaryPage> createState() => _AISummaryPageState();
}

class _AISummaryPageState extends State<AISummaryPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _summary;
  String? _error;
  DateTime? _generatedAt;
  int? _reportCount;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAISummary();
      if (response['success']) {
        setState(() {
          _summary = response['data']['summary'];
          _generatedAt = DateTime.parse(response['data']['generatedAt']);
          _reportCount = response['data']['reportCount'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?['message'] ?? 'Failed to load summary';
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
        title: const Text('AI Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSummary,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_reportCount != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.description, color: AppTheme.primaryGreen),
                                const SizedBox(width: 8),
                                Text('Based on $_reportCount reports'),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Health Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _summary ?? 'No summary available',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_generatedAt != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Generated: ${_generatedAt!.toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

