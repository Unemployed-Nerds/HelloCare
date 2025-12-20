import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../utils/theme.dart';
import '../../utils/glass_effects.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/pdf_viewer.dart';
import '../../models/report.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final String? downloadUrl; // Optional: for QR code access
  final Map<String, dynamic>? reportData; // Optional: for QR code access

  const ReportDetailPage({
    super.key, 
    required this.reportId,
    this.downloadUrl,
    this.reportData,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _downloadUrl;
  bool _isLoadingUrl = false;
  String? _urlError;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // If downloadUrl is provided (e.g., from QR code), use it directly
    if (widget.downloadUrl != null && widget.downloadUrl!.isNotEmpty) {
      _downloadUrl = widget.downloadUrl;
      _isLoadingUrl = false;
    } else {
      // Otherwise, load it from the API
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDownloadUrl();
      });
    }
  }

  Future<void> _loadDownloadUrl() async {
    setState(() {
      _isLoadingUrl = true;
      _urlError = null;
    });

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    try {
      print('Loading download URL for report: ${widget.reportId}');
      final url = await reportProvider.getDownloadUrl(widget.reportId);
      print('Download URL received: $url');
      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _isLoadingUrl = false;
          if (url == null || url.isEmpty) {
            _urlError = reportProvider.error ?? 'Failed to get download URL';
            print('Download URL is null or empty. Error: ${reportProvider.error}');
          } else {
            print('Setting download URL: $url');
          }
        });
      }
    } catch (e, stackTrace) {
      print('Exception loading download URL: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingUrl = false;
          _urlError = 'Error loading file: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If reportData is provided (e.g., from QR code), use it directly
    if (widget.reportData != null) {
      return _buildReportView(widget.reportData!);
    }

    // Otherwise, load from provider
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
        return _buildReportViewFromModel(report);
      },
    );
  }

  Future<void> _handleDelete() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: const Text(
          'Delete Report',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser != null) {
      final success = await reportProvider.deleteReport(
        widget.reportId,
        userProvider.currentUser!.userId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report deleted successfully'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          // Navigate back
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/patient/reports');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.error ?? 'Failed to delete report'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Widget _buildReportView(Map<String, dynamic> reportData) {
    final title = reportData['title']?.toString() ?? 'Report';
    final fileType = reportData['fileType']?.toString() ?? 'pdf';
    final category = reportData['category']?.toString();
    final doctorName = reportData['doctorName']?.toString();
    final clinicName = reportData['clinicName']?.toString();
    
    // Parse report date
    String reportDateStr = 'N/A';
    final reportDate = reportData['reportDate'];
    if (reportDate != null) {
      if (reportDate is String) {
        try {
          final date = DateTime.parse(reportDate);
          reportDateStr = date.toString().split(' ')[0];
        } catch (e) {
          reportDateStr = reportDate;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
              tooltip: 'Delete Report',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF/Image Viewer Section
            if (_isLoadingUrl)
              const SizedBox(
                height: 600,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_urlError != null || _downloadUrl == null)
              SizedBox(
                height: 600,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _urlError ?? 'Failed to load file',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDownloadUrl,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (fileType.toLowerCase() == 'pdf')
              PDFViewer(url: _downloadUrl!)
            else
              _ImageWidget(downloadUrl: _downloadUrl!, onRetry: _loadDownloadUrl),
            const SizedBox(height: 32),
            // Divider before Additional Details
            Divider(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              thickness: 2,
              height: 1,
            ),
            const SizedBox(height: 24),
            // Additional Details Section
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
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category field
            if (category != null)
              _buildDetailRow('Category', category, AppTheme.primaryGreen, AppTheme.primaryGreenLight),
            // Doctor field
            if (doctorName != null)
              _buildDetailRow('Doctor', doctorName, AppTheme.accentBlue, AppTheme.primaryGreenDark),
            // Clinic field
            if (clinicName != null)
              _buildDetailRow('Clinic', clinicName, AppTheme.accentPink, AppTheme.errorRed),
            // Report Date field
            _buildDetailRow('Report Date', reportDateStr, AppTheme.primaryGreenDark, AppTheme.darkGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: GlassEffects.glassCard(
              primaryColor: primaryColor,
              accentColor: accentColor,
              opacity: 0.5,
              borderRadius: 12.0,
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportViewFromModel(Report report) {
    return Scaffold(
          backgroundColor: AppTheme.backgroundGreen,
          appBar: AppBar(
            title: Text(report.title),
            actions: [
              if (_isDeleting)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _handleDelete,
                  tooltip: 'Delete Report',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PDF/Image Viewer Section (no background)
                if (_isLoadingUrl)
                  const SizedBox(
                    height: 600,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_urlError != null || _downloadUrl == null)
                  SizedBox(
                    height: 600,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _urlError ?? 'Failed to load file',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDownloadUrl,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (report.fileType == 'pdf')
                  PDFViewer(url: _downloadUrl!)
                else
                  _ImageWidget(downloadUrl: _downloadUrl!, onRetry: _loadDownloadUrl),
                const SizedBox(height: 32),
                // Divider before Additional Details
                Divider(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  thickness: 2,
                  height: 1,
                ),
                const SizedBox(height: 24),
                // Additional Details Section
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
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Category field
                if (report.category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: GlassEffects.glassCard(
                            primaryColor: AppTheme.primaryGreen,
                            accentColor: AppTheme.primaryGreenLight,
                            opacity: 0.5,
                            borderRadius: 12.0,
                          ),
                          child: const Text(
                            'Category',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              report.category!,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Doctor field
                if (report.doctorName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: GlassEffects.glassCard(
                            primaryColor: AppTheme.accentBlue,
                            accentColor: AppTheme.primaryGreenDark,
                            opacity: 0.5,
                            borderRadius: 12.0,
                          ),
                          child: const Text(
                            'Doctor',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              report.doctorName!,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Clinic field
                if (report.clinicName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: GlassEffects.glassCard(
                            primaryColor: AppTheme.accentPink,
                            accentColor: AppTheme.errorRed,
                            opacity: 0.5,
                            borderRadius: 12.0,
                          ),
                          child: const Text(
                            'Clinic',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              report.clinicName!,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Report Date field
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: GlassEffects.glassCard(
                          primaryColor: AppTheme.primaryGreenDark,
                          accentColor: AppTheme.darkGreen,
                          opacity: 0.5,
                          borderRadius: 12.0,
                        ),
                        child: const Text(
                          'Report Date',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            report.reportDate.toString().split(' ')[0],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Uploaded Date field
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: GlassEffects.glassCard(
                          primaryColor: AppTheme.surfaceVariant,
                          accentColor: AppTheme.accentPurple,
                          opacity: 0.5,
                          borderRadius: 12.0,
                        ),
                        child: const Text(
                          'Uploaded',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            report.uploadDate.toString().split(' ')[0],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

/// Custom image widget that handles Firebase Storage signed URLs better
class _ImageWidget extends StatefulWidget {
  final String downloadUrl;
  final VoidCallback onRetry;

  const _ImageWidget({
    required this.downloadUrl,
    required this.onRetry,
  });

  @override
  State<_ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<_ImageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading image from URL: ${widget.downloadUrl}');
      final response = await http.get(Uri.parse(widget.downloadUrl));
      
      print('Image response status: ${response.statusCode}');
      print('Image response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
        print('Image loaded successfully, size: ${_imageBytes?.length} bytes');
      } else {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading image: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 600,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      final is404 = _error!.contains('404') || _error!.toLowerCase().contains('not found');
      return SizedBox(
        height: 600,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.grey,
              ),
              const SizedBox(height: 16),
              Text(
                is404
                    ? 'File Not Found\n\nThe file may not have been uploaded successfully or may have been deleted.\nPlease contact support or re-upload the report.'
                    : 'Failed to load image\n$_error',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!is404)
                Text(
                  'URL: ${widget.downloadUrl.substring(0, widget.downloadUrl.length > 100 ? 100 : widget.downloadUrl.length)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadImage();
                  widget.onRetry();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Image.memory error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to display image\n$error',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadImage();
                    widget.onRetry();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox(
      height: 600,
      child: Center(child: Text('No image data')),
    );
  }
}


