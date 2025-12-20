import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AISummaryDisplay extends StatelessWidget {
  final Map<String, dynamic> summaryData;

  const AISummaryDisplay({
    super.key,
    required this.summaryData,
  });

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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return AppTheme.primaryGreen;
      case 'HIGH':
      case 'LOW':
        return AppTheme.errorRed;
      case 'PENDING':
        return AppTheme.grey;
      default:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute summary content before building widgets
    final overallSummary = summaryData['overallSummary']?.toString() ?? '';
    final strippedSummary = _stripMarkdown(overallSummary);
    final hasSummaryContent = strippedSummary.isNotEmpty && strippedSummary.length > 3;
    final hasCriticalSummary = summaryData['criticalSummary'] != null && 
        summaryData['criticalSummary'].toString().isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority and Overall Summary Section
          if (summaryData['priorityEmoji'] != null || hasSummaryContent || hasCriticalSummary)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summaryData['priorityEmoji'] != null)
                      Row(
                        children: [
                          Text(
                            summaryData['priorityEmoji'],
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Health Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (hasSummaryContent) ...[
                      if (summaryData['priorityEmoji'] != null) const SizedBox(height: 16),
                      Text(
                        strippedSummary,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ] else if (summaryData['overallSummary'] != null && overallSummary.isNotEmpty) ...[
                      // If summary exists but was stripped to nothing, show a message
                      if (summaryData['priorityEmoji'] != null) const SizedBox(height: 16),
                      Text(
                        'Summary data is being processed. Please refresh to see the full summary.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (summaryData['criticalSummary'] != null && 
                        summaryData['criticalSummary'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: AppTheme.errorRed),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _stripMarkdown(summaryData['criticalSummary'].toString()),
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Test Findings Section
          if (summaryData['findings'] != null && 
              (summaryData['findings'] as List).isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Test Results',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(summaryData['findings'] as List).map<Widget>((finding) {
              final status = finding['status']?.toString() ?? 'PENDING';
              final isCritical = finding['critical'] == true;
              final testName = _stripMarkdown(finding['testName']?.toString() ?? 'Unknown Test');
              final measuredValue = finding['measuredValue'];
              final rawValue = _stripMarkdown(finding['rawValue']?.toString() ?? '');
              final units = _stripMarkdown(finding['units']?.toString() ?? '');
              final referenceRange = _stripMarkdown(finding['referenceRangeRaw']?.toString() ?? '');
              final comments = finding['comments'] != null ? _stripMarkdown(finding['comments'].toString()) : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              testName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(status),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCritical)
                                  const Text('🚨 ', style: TextStyle(fontSize: 16)),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (measuredValue != null)
                        Row(
                          children: [
                            Text(
                              'Value: ',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$measuredValue ${units != 'N/A' ? units : ''}'.trim(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else if (rawValue.isNotEmpty)
                        Row(
                          children: [
                            Text(
                              'Value: ',
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                rawValue,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (referenceRange.isNotEmpty && referenceRange != 'N/A') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reference Range: $referenceRange',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (comments != null && comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          comments,
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],

          // Identified Panels
          if (summaryData['identifiedPanels'] != null &&
              (summaryData['identifiedPanels'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Test Panels',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (summaryData['identifiedPanels'] as List)
                  .map<Widget>((panel) => Chip(
                        label: Text(_stripMarkdown(panel.toString())),
                        backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],

          // Lifestyle Focus
          if (summaryData['suggestedLifestyleFocus'] != null &&
              (summaryData['suggestedLifestyleFocus'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Lifestyle Focus Areas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (summaryData['suggestedLifestyleFocus'] as List)
                  .map<Widget>((focus) => Chip(
                        label: Text(_stripMarkdown(focus.toString())),
                        backgroundColor: AppTheme.accentPink.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],

          // Education Search Terms
          if (summaryData['educationSearchTerms'] != null &&
              (summaryData['educationSearchTerms'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreenDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Learn More',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (summaryData['educationSearchTerms'] as List)
                  .map<Widget>((term) => Chip(
                        label: Text(_stripMarkdown(term.toString())),
                        backgroundColor: AppTheme.primaryGreenDark.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],

          // Confidence and Metadata
          if (summaryData['confidence'] != null ||
              summaryData['parsingNotes'] != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summaryData['confidence'] != null) ...[
                      Row(
                        children: [
                          const Text(
                            'Confidence: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey,
                            ),
                          ),
                          Text(
                            '${((summaryData['confidence'] as num) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (summaryData['parsingNotes'] != null &&
                        summaryData['parsingNotes'].toString().isNotEmpty) ...[
                      const Text(
                        'Notes:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stripMarkdown(summaryData['parsingNotes'].toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Report Date and Metadata
          if (summaryData['reportDate'] != null ||
              summaryData['reportId'] != null) ...[
            const SizedBox(height: 16),
            Text(
              summaryData['reportDate'] != null
                  ? 'Report Date: ${summaryData['reportDate']}'
                  : 'Report ID: ${summaryData['reportId']}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

