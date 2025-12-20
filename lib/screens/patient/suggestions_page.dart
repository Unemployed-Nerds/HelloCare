import 'dart:convert';
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
      print('Suggestions API Response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Suggestions Data: $data');
        print('Suggestions Data type: ${data.runtimeType}');
        
        List<Map<String, dynamic>> suggestionsList = [];
        
        // Handle different response formats
        if (data is Map && data.containsKey('suggestions')) {
          final suggestions = data['suggestions'];
          print('Suggestions field type: ${suggestions.runtimeType}');
          
          if (suggestions is List) {
            // Normal case: suggestions is already a list
            suggestionsList = suggestions.map((s) {
              if (s is Map) {
                final suggestionMap = Map<String, dynamic>.from(s);
                
                // Check if description contains markdown-wrapped JSON
                if (suggestionMap['description'] is String) {
                  String description = suggestionMap['description'] as String;
                  print('Original description: ${description.substring(0, description.length > 100 ? 100 : description.length)}...');
                  
                  // Check if description starts with ```json or contains ```json
                  if (description.trim().startsWith('```') || description.contains('```json')) {
                    print('Found markdown code block in description');
                    String jsonString = '';
                    
                    // First, try brace matching (most reliable for truncated strings)
                    final jsonStart = description.indexOf('{');
                    if (jsonStart != -1) {
                      print('Found opening brace at index $jsonStart, using brace matching...');
                      // Find the matching closing brace by counting braces
                      int braceCount = 0;
                      int jsonEnd = -1;
                      for (int i = jsonStart; i < description.length; i++) {
                        if (description[i] == '{') braceCount++;
                        if (description[i] == '}') {
                          braceCount--;
                          if (braceCount == 0) {
                            jsonEnd = i + 1;
                            break;
                          }
                        }
                      }
                      if (jsonEnd > jsonStart) {
                        jsonString = description.substring(jsonStart, jsonEnd).trim();
                        print('Extracted JSON using brace matching, length: ${jsonString.length}');
                      } else {
                        print('Could not find matching closing brace, JSON may be truncated');
                        // If no closing brace found, try regex patterns as fallback
                        var codeBlockPattern = RegExp(r'```[a-zA-Z]*\s*\n([\s\S]*?)```', dotAll: true);
                        var match = codeBlockPattern.firstMatch(description);
                        if (match == null) {
                          codeBlockPattern = RegExp(r'```[a-zA-Z]*\s*\n([\s\S]*)', dotAll: true);
                          match = codeBlockPattern.firstMatch(description);
                        }
                        if (match != null) {
                          jsonString = match.group(1)?.trim() ?? '';
                          print('Extracted JSON using regex fallback, length: ${jsonString.length}');
                        }
                      }
                    } else {
                      print('No opening brace found, trying regex patterns...');
                      // Fallback to regex if no brace found
                      var codeBlockPattern = RegExp(r'```[a-zA-Z]*\s*\n([\s\S]*?)```', dotAll: true);
                      var match = codeBlockPattern.firstMatch(description);
                      if (match == null) {
                        codeBlockPattern = RegExp(r'```[a-zA-Z]*\s*\n([\s\S]*)', dotAll: true);
                        match = codeBlockPattern.firstMatch(description);
                      }
                      if (match != null) {
                        jsonString = match.group(1)?.trim() ?? '';
                        print('Extracted JSON using regex pattern, length: ${jsonString.length}');
                      }
                    }
                    
                    if (jsonString.isNotEmpty) {
                      print('Extracted JSON string length: ${jsonString.length}');
                      print('JSON string preview: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}...');
                      
                      // Check if JSON appears to be truncated or has invalid characters
                      String jsonToParse = jsonString;
                      bool shouldTryParsing = true;
                      
                      // Check for common truncation indicators
                      if (!jsonString.trim().endsWith('}') && !jsonString.trim().endsWith(']')) {
                        print('JSON appears truncated (doesn\'t end with } or ]), trying to find complete structure...');
                        // Try to find the last complete closing brace
                        int lastBrace = jsonString.lastIndexOf('}');
                        if (lastBrace != -1) {
                          // Check if this brace closes the root object
                          int braceCount = 0;
                          for (int i = 0; i <= lastBrace; i++) {
                            if (jsonString[i] == '{') braceCount++;
                            if (jsonString[i] == '}') braceCount--;
                          }
                          if (braceCount == 0) {
                            jsonToParse = jsonString.substring(0, lastBrace + 1);
                            print('Using truncated JSON up to last complete brace, length: ${jsonToParse.length}');
                          } else {
                            // Try to complete the JSON by finding matching braces from the start
                            int braceCount2 = 0;
                            int completeEnd = -1;
                            for (int i = 0; i < jsonString.length; i++) {
                              if (jsonString[i] == '{') braceCount2++;
                              if (jsonString[i] == '}') {
                                braceCount2--;
                                if (braceCount2 == 0 && completeEnd == -1) {
                                  completeEnd = i;
                                }
                              }
                            }
                            if (completeEnd != -1) {
                              jsonToParse = jsonString.substring(0, completeEnd + 1);
                              print('Using JSON up to root closing brace, length: ${jsonToParse.length}');
                            } else {
                              print('Could not find complete JSON structure, will use fallback extraction');
                              shouldTryParsing = false;
                            }
                          }
                        } else {
                          print('No closing brace found, will use fallback extraction');
                          shouldTryParsing = false;
                        }
                      }
                      
                      // Check for invalid characters that would cause parse errors
                      if (shouldTryParsing && jsonToParse.contains('...')) {
                        print('JSON contains "..." which indicates truncation, will use fallback extraction');
                        shouldTryParsing = false;
                      }
                      
                      if (shouldTryParsing) {
                        try {
                          final parsed = json.decode(jsonToParse);
                        print('Successfully parsed JSON, type: ${parsed.runtimeType}');
                        if (parsed is Map) {
                          print('Parsed JSON is a Map with keys: ${parsed.keys.toList()}');
                          // If the JSON contains findings, generate suggestions from them
                          final findings = parsed['findings'] as List?;
                          if (findings != null && findings.isNotEmpty) {
                            // Generate suggestions from findings
                            final List<String> suggestionTexts = [];
                            
                            // Group findings by status
                            final highFindings = findings.where((f) => 
                              f is Map && f['status'] == 'HIGH'
                            ).toList();
                            final lowFindings = findings.where((f) => 
                              f is Map && f['status'] == 'LOW'
                            ).toList();
                            final criticalFindings = findings.where((f) => 
                              f is Map && f['critical'] == true
                            ).toList();
                            
                            // Generate suggestions based on findings
                            if (criticalFindings.isNotEmpty) {
                              for (var finding in criticalFindings) {
                                final f = finding as Map;
                                final testName = f['testName']?.toString() ?? 'test';
                                suggestionTexts.add('🚨 Your $testName requires immediate attention. Please consult with your healthcare provider as soon as possible.');
                              }
                            }
                            
                            if (highFindings.isNotEmpty) {
                              for (var finding in highFindings) {
                                final f = finding as Map;
                                final testName = f['testName']?.toString() ?? 'test';
                                final value = f['measuredValue'] ?? f['rawValue'] ?? '';
                                final units = f['units']?.toString() ?? '';
                                
                                // Generate specific suggestions based on test type
                                String suggestion = '';
                                if (testName.toLowerCase().contains('cholesterol')) {
                                  suggestion = 'Your Total Cholesterol is elevated ($value${units.isNotEmpty ? ' $units' : ''}). Consider reducing saturated fats, increasing fiber intake, and regular exercise.';
                                } else if (testName.toLowerCase().contains('glucose') || testName.toLowerCase().contains('sugar')) {
                                  suggestion = 'Your blood glucose is elevated ($value${units.isNotEmpty ? ' $units' : ''}). Consider reducing sugar intake, maintaining regular meal times, and increasing physical activity.';
                                } else if (testName.toLowerCase().contains('pressure')) {
                                  suggestion = 'Your blood pressure is elevated ($value${units.isNotEmpty ? ' $units' : ''}). Consider reducing sodium intake, regular exercise, and stress management.';
                                } else {
                                  suggestion = 'Your $testName is HIGH ($value${units.isNotEmpty ? ' $units' : ''}). Discuss these results with your healthcare provider for personalized recommendations.';
                                }
                                suggestionTexts.add(suggestion);
                              }
                            }
                            
                            if (lowFindings.isNotEmpty) {
                              for (var finding in lowFindings) {
                                final f = finding as Map;
                                final testName = f['testName']?.toString() ?? 'test';
                                suggestionTexts.add('Your $testName is below normal range. Please discuss with your healthcare provider for appropriate management.');
                              }
                            }
                            
                            if (suggestionTexts.isEmpty) {
                              // All findings are normal
                              suggestionMap['description'] = 'Your test results show normal values. Continue maintaining a healthy lifestyle with balanced nutrition and regular exercise.';
                            } else {
                              suggestionMap['description'] = suggestionTexts.join('\n\n');
                            }
                            
                            print('Generated description: ${suggestionMap['description']}');
                            
                            // Update title based on findings
                            if (criticalFindings.isNotEmpty) {
                              suggestionMap['title'] = 'Critical Health Alert';
                              suggestionMap['priority'] = 'high';
                            } else if (highFindings.isNotEmpty || lowFindings.isNotEmpty) {
                              suggestionMap['title'] = 'Health Recommendations';
                              suggestionMap['priority'] = 'medium';
                            }
                          } else {
                            print('No findings found in parsed JSON');
                            // No findings, use overall summary if available
                            final overallSummary = parsed['overallSummary']?.toString() ?? 
                                                  parsed['summary']?.toString() ?? 
                                                  'Review your test results and consult with your healthcare provider for personalized recommendations.';
                            suggestionMap['description'] = _stripMarkdown(overallSummary);
                            print('Using overall summary: ${suggestionMap['description']}');
                          }
                        } else {
                          print('Parsed JSON is not a Map, type: ${parsed.runtimeType}');
                        }
                        } catch (e) {
                          print('JSON parsing failed, will use fallback extraction: $e');
                          shouldTryParsing = false;
                        }
                      }
                      
                      // If parsing failed or was skipped, use fallback regex extraction
                      if (!shouldTryParsing) {
                        print('Using fallback regex extraction for partial JSON');
                        // If parsing fails, try to extract findings from partial JSON using string matching
                        try {
                          // Look for testName and status patterns in the JSON string
                          final testNameMatch = RegExp(r'"testName"\s*:\s*"([^"]+)"').firstMatch(jsonString);
                          final statusMatch = RegExp(r'"status"\s*:\s*"([^"]+)"').firstMatch(jsonString);
                          final valueMatch = RegExp(r'"measuredValue"\s*:\s*([0-9.]+)').firstMatch(jsonString);
                          final unitsMatch = RegExp(r'"units"\s*:\s*"([^"]+)"').firstMatch(jsonString);
                          
                          if (testNameMatch != null && statusMatch != null) {
                            final testName = testNameMatch.group(1) ?? 'test';
                            final status = statusMatch.group(1) ?? '';
                            final value = valueMatch?.group(1) ?? '';
                            final units = unitsMatch?.group(1) ?? '';
                            
                            if (status == 'HIGH') {
                              String suggestion = '';
                              if (testName.toLowerCase().contains('cholesterol')) {
                                suggestion = 'Your Total Cholesterol is elevated${value.isNotEmpty ? ' ($value${units.isNotEmpty ? ' $units' : ''})' : ''}. Consider reducing saturated fats, increasing fiber intake, and regular exercise.';
                              } else {
                                suggestion = 'Your $testName is HIGH${value.isNotEmpty ? ' ($value${units.isNotEmpty ? ' $units' : ''})' : ''}. Discuss these results with your healthcare provider for personalized recommendations.';
                              }
                              suggestionMap['description'] = suggestion;
                              suggestionMap['title'] = 'Health Recommendations';
                              suggestionMap['priority'] = 'medium';
                              print('Generated suggestion from partial JSON parsing');
                            } else {
                              suggestionMap['description'] = 'Your test results show normal values. Continue maintaining a healthy lifestyle with balanced nutrition and regular exercise.';
                            }
                          } else {
                            // Fallback: remove markdown and use as plain text
                            suggestionMap['description'] = _stripMarkdown(jsonString);
                            if (suggestionMap['description'].toString().trim().isEmpty || 
                                suggestionMap['description'].toString().length < 20) {
                              suggestionMap['description'] = 'Please review your test results and consult with your healthcare provider for personalized recommendations.';
                            }
                          }
                        } catch (e2) {
                          print('Fallback parsing also failed: $e2');
                          suggestionMap['description'] = 'Please review your test results and consult with your healthcare provider for personalized recommendations.';
                        }
                      }
                    } else {
                      print('Could not extract JSON from description');
                      // Fallback: try to strip markdown and use as-is
                      suggestionMap['description'] = _stripMarkdown(description);
                      if (suggestionMap['description'].toString().trim().isEmpty || 
                          suggestionMap['description'].toString().length < 10) {
                        suggestionMap['description'] = 'Please review your test results and consult with your healthcare provider.';
                      }
                    }
                  } else {
                    // Description is not markdown, just strip any markdown that might be there
                    suggestionMap['description'] = _stripMarkdown(description);
                  }
                } else {
                  print('Description is not a string, type: ${suggestionMap['description'].runtimeType}');
                }
                
                // Remove "(unstructured)" from title
                if (suggestionMap['title'] is String) {
                  String title = suggestionMap['title'] as String;
                  title = title.replaceAll(RegExp(r'\(unstructured\)', caseSensitive: false), '').trim();
                  if (title.isEmpty || title.toLowerCase().contains('ai generated suggestions')) {
                    // Generate a better title based on type or priority
                    final type = suggestionMap['type']?.toString() ?? '';
                    final priority = suggestionMap['priority']?.toString() ?? '';
                    if (type.isNotEmpty) {
                      title = type.substring(0, 1).toUpperCase() + type.substring(1) + ' Recommendation';
                    } else if (priority == 'high') {
                      title = 'Important Health Recommendation';
                    } else {
                      title = 'Health Recommendation';
                    }
                  }
                  suggestionMap['title'] = title;
                }
                
                return suggestionMap;
              } else if (s is String) {
                // If suggestion is a string, try to parse it
                try {
                  final parsed = json.decode(s);
                  return parsed is Map ? Map<String, dynamic>.from(parsed) : {'title': s, 'description': s};
                } catch (e) {
                  return {'title': 'Suggestion', 'description': s};
                }
              } else {
                return {'title': 'Suggestion', 'description': s.toString()};
              }
            }).toList();
          } else if (suggestions is String) {
            // Suggestions might be a JSON string wrapped in markdown
            String cleanedSuggestions = suggestions;
            
            // Remove markdown code blocks
            final codeBlockPattern = RegExp(r'```[a-zA-Z]*\n?([\s\S]*?)```');
            final match = codeBlockPattern.firstMatch(suggestions);
            if (match != null) {
              cleanedSuggestions = match.group(1)?.trim() ?? suggestions;
            }
            
            try {
              final decoded = json.decode(cleanedSuggestions);
              if (decoded is List) {
                suggestionsList = decoded.map((s) => s is Map ? Map<String, dynamic>.from(s) : {'title': 'Suggestion', 'description': s.toString()}).toList();
              } else if (decoded is Map && decoded.containsKey('suggestions')) {
                final nestedSuggestions = decoded['suggestions'];
                if (nestedSuggestions is List) {
                  suggestionsList = nestedSuggestions.map((s) => s is Map ? Map<String, dynamic>.from(s) : {'title': 'Suggestion', 'description': s.toString()}).toList();
                }
              }
            } catch (e) {
              print('Failed to parse suggestions string: $e');
            }
          }
        } else if (data is List) {
          // Data is directly a list
          suggestionsList = data.map((s) => s is Map ? Map<String, dynamic>.from(s) : {'title': 'Suggestion', 'description': s.toString()}).toList();
        } else if (data is String) {
          // Data is a string, try to parse it
          String cleanedData = data;
          final codeBlockPattern = RegExp(r'```[a-zA-Z]*\n?([\s\S]*?)```');
          final match = codeBlockPattern.firstMatch(data);
          if (match != null) {
            cleanedData = match.group(1)?.trim() ?? data;
          }
          
          try {
            final decoded = json.decode(cleanedData);
            if (decoded is Map && decoded.containsKey('suggestions')) {
              final suggestions = decoded['suggestions'];
              if (suggestions is List) {
                suggestionsList = suggestions.map((s) => s is Map ? Map<String, dynamic>.from(s) : {'title': 'Suggestion', 'description': s.toString()}).toList();
              }
            } else if (decoded is List) {
              suggestionsList = decoded.map((s) => s is Map ? Map<String, dynamic>.from(s) : {'title': 'Suggestion', 'description': s.toString()}).toList();
            }
          } catch (e) {
            print('Failed to parse data string: $e');
          }
        }
        
        // Final pass: ensure all descriptions are cleaned
        for (var i = 0; i < suggestionsList.length; i++) {
          final suggestion = suggestionsList[i];
          if (suggestion['description'] is String) {
            final desc = suggestion['description'] as String;
            if (desc.contains('```json') || desc.trim().startsWith('```')) {
              print('Warning: Description still contains markdown at index $i, cleaning...');
              suggestion['description'] = _stripMarkdown(desc);
              // If still empty or just markdown, provide fallback
              if (suggestion['description'].toString().trim().isEmpty || 
                  suggestion['description'].toString().trim() == desc.trim()) {
                suggestion['description'] = 'Please review your test results and consult with your healthcare provider.';
              }
            }
          }
        }
        
        print('Processed suggestions count: ${suggestionsList.length}');
        for (var i = 0; i < suggestionsList.length; i++) {
          final s = suggestionsList[i];
          print('Suggestion $i: title="${s['title']}", description="${(s['description']?.toString() ?? '').substring(0, (s['description']?.toString() ?? '').length > 100 ? 100 : (s['description']?.toString() ?? '').length)}..."');
        }
        
        setState(() {
          _suggestions = suggestionsList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error']?['message'] ?? 'Failed to load suggestions';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading suggestions: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isDietRelated(Map<String, dynamic> suggestion) {
    final type = (suggestion['type'] ?? '').toString().toLowerCase();
    final title = (suggestion['title'] ?? '').toString().toLowerCase();
    final description = (suggestion['description'] ?? '').toString().toLowerCase();
    
    return type == 'diet' || 
           title.contains('diet') || 
           title.contains('food') || 
           title.contains('nutrition') ||
           title.contains('meal') ||
           description.contains('diet') ||
           description.contains('food') ||
           description.contains('nutrition') ||
           description.contains('meal');
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return AppTheme.accentPink;
      default:
        return AppTheme.primaryGreen;
    }
  }

  // Helper function to strip markdown formatting from text
  String _stripMarkdown(String text) {
    if (text.isEmpty) return text;
    // Use replaceAllMapped to properly handle capture groups
    String result = text;
    // Remove code blocks first (including ```json ... ``` and ``` ... ```)
    result = result.replaceAll(RegExp(r'```[a-zA-Z]*\n?[\s\S]*?```'), ''); // Code blocks with optional language identifier
    result = result.replaceAll(RegExp(r'```[\s\S]*?```'), ''); // Code blocks without language identifier (fallback)
    result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1) ?? ''); // Bold **text**
    result = result.replaceAllMapped(RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'), (match) => match.group(1) ?? ''); // Italic *text* (not bold)
    result = result.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match.group(1) ?? ''); // Bold __text__
    result = result.replaceAllMapped(RegExp(r'(?<!_)_([^_]+)_(?!_)'), (match) => match.group(1) ?? ''); // Italic _text_ (not bold)
    result = result.replaceAllMapped(RegExp(r'#{1,6}\s+(.+)'), (match) => match.group(1) ?? ''); // Headers # text
    result = result.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (match) => match.group(1) ?? ''); // Links [text](url)
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? ''); // Inline code `code`
    result = result.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), ''); // List items
    result = result.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), ''); // Numbered lists
    // Remove "(unstructured)" text if present
    result = result.replaceAll(RegExp(r'\(unstructured\)', caseSensitive: false), '').trim();
    return result.trim();
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion) {
    final priority = suggestion['priority'] ?? 'low';
    final priorityColor = _getPriorityColor(priority);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor,
          radius: 20,
          child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _stripMarkdown(suggestion['title']?.toString() ?? 'Suggestion'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                (priority).toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              backgroundColor: priorityColor.withOpacity(0.2),
              labelStyle: TextStyle(color: priorityColor),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: Icon(
          Icons.expand_more,
          color: AppTheme.primaryGreen,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            _stripMarkdown(suggestion['description']?.toString() ?? 'No description available'),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          if (suggestion['type'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Type: ${_stripMarkdown(suggestion['type']?.toString() ?? '')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> suggestions, IconData icon) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestions.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...suggestions.map((suggestion) => _buildSuggestionTile(suggestion)),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> dietSuggestions = [];
    List<Map<String, dynamic>> otherSuggestions = [];

    if (_suggestions != null) {
      for (var suggestion in _suggestions!) {
        if (_isDietRelated(suggestion)) {
          dietSuggestions.add(suggestion);
        } else {
          otherSuggestions.add(suggestion);
        }
      }
    }

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
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
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
                      child: Text(
                        'No suggestions available',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            'Diet & Nutrition',
                            dietSuggestions,
                            Icons.restaurant,
                          ),
                          _buildSection(
                            'Other Suggestions',
                            otherSuggestions,
                            Icons.medical_services,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

