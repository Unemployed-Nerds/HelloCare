import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../services/api_service.dart';

class SuggestionsPage extends StatefulWidget {
  const SuggestionsPage({super.key});

  @override
  State<SuggestionsPage> createState() => _SuggestionsPageState();
}

class _SuggestionsPageState extends State<SuggestionsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>>? _suggestions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAISuggestions();
      if (response['success']) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(response['data']['suggestions']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?['message'] ?? 'Failed to load suggestions';
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return Colors.orange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('AI Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
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
                        onPressed: _loadSuggestions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _suggestions == null || _suggestions!.isEmpty
                  ? const Center(
                      child: Text('No suggestions available'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _suggestions!.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getPriorityColor(
                                suggestion['priority'] ?? 'low',
                              ),
                              child: const Icon(Icons.lightbulb, color: Colors.white),
                            ),
                            title: Text(
                              suggestion['title'] ?? 'Suggestion',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(suggestion['description'] ?? ''),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    (suggestion['priority'] ?? 'low').toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _getPriorityColor(
                                    suggestion['priority'] ?? 'low',
                                  ).withOpacity(0.2),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}

