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
  List<String>? _relatedImageUrls;
  List<String>? _relatedReportIds;
  bool _isLoadingUrl = false;
  String? _urlError;
  bool _isDeleting = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // If downloadUrl is provided (e.g., from QR code), use it directly
    if (widget.downloadUrl != null && widget.downloadUrl!.isNotEmpty) {
      _downloadUrl = widget.downloadUrl;
      _isLoadingUrl = false;
      _isInitialLoad = false;
    } else {
      // Otherwise, load it from the API
      // Set loading state immediately to prevent blank flash
      _isLoadingUrl = true;
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
      
      // Load the report to check for related images
      final report = await reportProvider.getReport(widget.reportId);
      if (report != null && report.fileType == 'image') {
        // Find related reports with same title and date
        await _loadRelatedImages(report, reportProvider);
      }
      
      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _isLoadingUrl = false;
          _isInitialLoad = false;
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
          _isInitialLoad = false;
          _urlError = 'Error loading file: $e';
        });
      }
    }
  }

  Future<void> _loadRelatedImages(Report currentReport, ReportProvider reportProvider) async {
    try {
      // Get all reports from provider
      final allReports = reportProvider.reports;
      
      // Find reports with same title, same report date, and fileType == 'image'
      final relatedReports = allReports.where((r) =>
        r.reportId != currentReport.reportId &&
        r.fileType == 'image' &&
        r.title == currentReport.title &&
        r.reportDate.year == currentReport.reportDate.year &&
        r.reportDate.month == currentReport.reportDate.month &&
        r.reportDate.day == currentReport.reportDate.day
      ).toList();
      
      if (relatedReports.isNotEmpty) {
        // Add current report to the list
        final allRelatedReports = [currentReport, ...relatedReports];
        // Sort by upload date to maintain order
        allRelatedReports.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
        
        // Load download URLs for all related reports
        final List<String> urls = [];
        final List<String> reportIds = [];
        
        for (final report in allRelatedReports) {
          final url = await reportProvider.getDownloadUrl(report.reportId);
          if (url != null && url.isNotEmpty) {
            urls.add(url);
            reportIds.add(report.reportId);
          }
        }
        
        if (mounted && urls.length > 1) {
          // Only set if there are multiple images (more than just the current one)
          setState(() {
            _relatedImageUrls = urls;
            _relatedReportIds = reportIds;
          });
        }
      }
    } catch (e) {
      print('Error loading related images: $e');
      // Don't fail the whole page if related images can't be loaded
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
            backgroundColor: AppTheme.backgroundGreen,
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundGreen,
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: Text('Report not found')),
          );
        }

        final report = snapshot.data!;
        
        // Show loading state until download URL is ready (prevents blank flash)
        if (_isInitialLoad || (_isLoadingUrl && _downloadUrl == null)) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundGreen,
            appBar: AppBar(title: const Text('Report Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
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
            if (_isLoadingUrl && _downloadUrl == null)
              const SizedBox(
                height: 600,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_urlError != null || (_downloadUrl == null && !_isLoadingUrl))
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
              _ImageWidget(
                downloadUrl: _downloadUrl!,
                relatedImageUrls: null, // Can't load related images from reportData
                onRetry: _loadDownloadUrl,
              ),
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
                if (_isLoadingUrl && _downloadUrl == null)
                  const SizedBox(
                    height: 600,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_urlError != null || (_downloadUrl == null && !_isLoadingUrl))
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
                  _ImageWidget(
                    downloadUrl: _downloadUrl!,
                    relatedImageUrls: _relatedImageUrls,
                    onRetry: _loadDownloadUrl,
                  ),
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
  final List<String>? relatedImageUrls;
  final VoidCallback onRetry;

  const _ImageWidget({
    required this.downloadUrl,
    this.relatedImageUrls,
    required this.onRetry,
  });

  @override
  State<_ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<_ImageWidget> {
  Uint8List? _imageBytes;
  Map<int, Uint8List> _relatedImageBytes = {};
  bool _isLoading = true;
  String? _error;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Find initial index if multiple images
    int initialIndex = 0;
    if (_hasMultipleImages()) {
      final allUrls = _getAllImageUrls();
      initialIndex = allUrls.indexOf(widget.downloadUrl);
      if (initialIndex < 0) initialIndex = 0;
    }
    _pageController = PageController(initialPage: initialIndex);
    _currentIndex = initialIndex;
    _loadImage();
    if (_hasMultipleImages()) {
      _loadRelatedImages();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _hasMultipleImages() {
    return widget.relatedImageUrls != null && widget.relatedImageUrls!.isNotEmpty;
  }

  List<String> _getAllImageUrls() {
    if (_hasMultipleImages()) {
      return widget.relatedImageUrls!;
    }
    return [widget.downloadUrl];
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

  Future<void> _loadRelatedImages() async {
    if (!_hasMultipleImages()) return;
    
    final urls = widget.relatedImageUrls!;
    for (int i = 0; i < urls.length; i++) {
      if (urls[i] == widget.downloadUrl) {
        // Current image already loaded
        _relatedImageBytes[i] = _imageBytes!;
        continue;
      }
      
      try {
        final response = await http.get(Uri.parse(urls[i]));
        if (response.statusCode == 200) {
          setState(() {
            _relatedImageBytes[i] = response.bodyBytes;
          });
        }
      } catch (e) {
        print('Error loading related image $i: $e');
      }
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
      final allUrls = _getAllImageUrls();
      final hasMultiple = _hasMultipleImages();
      
      // If multiple images, show slider with dots
      if (hasMultiple && allUrls.length > 1) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 570, // Same height as PDF viewer
              child: PageView.builder(
                controller: _pageController,
                itemCount: allUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Load image if not already loaded
                  if (!_relatedImageBytes.containsKey(index) && index > 0) {
                    _loadImageAtIndex(index);
                  }
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Open full-screen image viewer
                      final allBytes = _getAllImageBytes();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => _FullScreenImageViewer(
                            imageUrls: allUrls,
                            imageBytes: allBytes,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: _buildImagePage(index, allUrls[index]),
                  );
                },
              ),
            ),
            // Dots indicator (same style as PDF viewer)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? const Color(0xFF9C914F)
                          : const Color(0xFF9C914F).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      
      // Single image
      return GestureDetector(
        onTap: () {
          // Open full-screen image viewer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _FullScreenImageViewer(
                imageUrls: [widget.downloadUrl],
                imageBytes: [_imageBytes!],
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Image.memory(
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
        ),
      );
    }

    return const SizedBox(
      height: 600,
      child: Center(child: Text('No image data')),
    );
  }

  Widget _buildImagePage(int index, String url) {
    Uint8List? imageBytes;
    if (index == 0) {
      imageBytes = _imageBytes;
    } else {
      imageBytes = _relatedImageBytes[index];
    }

    if (imageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Image.memory(
      imageBytes,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadImageAtIndex(int index) async {
    if (!_hasMultipleImages() || index >= widget.relatedImageUrls!.length) {
      return;
    }

    final url = widget.relatedImageUrls![index];
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _relatedImageBytes[index] = response.bodyBytes;
        });
      }
    } catch (e) {
      print('Error loading image at index $index: $e');
    }
  }

  List<Uint8List> _getAllImageBytes() {
    final allUrls = _getAllImageUrls();
    final List<Uint8List> bytes = [];
    
    for (int i = 0; i < allUrls.length; i++) {
      if (i == 0) {
        if (_imageBytes != null) bytes.add(_imageBytes!);
      } else {
        if (_relatedImageBytes.containsKey(i)) {
          bytes.add(_relatedImageBytes[i]!);
        }
      }
    }
    
    return bytes;
  }
}

/// Full-screen image viewer with swipeable support for multiple images
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final List<Uint8List>? imageBytes;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    this.imageBytes,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, Uint8List?> _loadedImages = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};
  final Map<int, TransformationController> _transformationControllers = {};
  final Map<int, bool> _isZoomed = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize transformation controllers for all images
    for (int i = 0; i < widget.imageUrls.length; i++) {
      _transformationControllers[i] = TransformationController();
      _isZoomed[i] = false;
      // Add listener to detect zoom state
      _transformationControllers[i]!.addListener(() {
        if (mounted) {
          final matrix = _transformationControllers[i]!.value;
          final isZoomed = matrix.getMaxScaleOnAxis() > 1.01; // Use 1.01 to account for floating point precision
          if (_isZoomed[i] != isZoomed) {
            setState(() {
              _isZoomed[i] = isZoomed;
            });
          }
        }
      });
    }
    
    // Pre-load initial image bytes if provided
    if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
      for (int i = 0; i < widget.imageBytes!.length && i < widget.imageUrls.length; i++) {
        _loadedImages[i] = widget.imageBytes![i];
        _loadingStates[i] = false;
      }
    }
    
    // Load initial image if not already loaded
    if (!_loadedImages.containsKey(_currentIndex)) {
      _loadImage(_currentIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadImage(int index) async {
    if (_loadedImages.containsKey(index) || _loadingStates[index] == true) {
      return;
    }

    setState(() {
      _loadingStates[index] = true;
      _errorStates[index] = null;
    });

    try {
      final response = await http.get(Uri.parse(widget.imageUrls[index]));
      if (response.statusCode == 200) {
        setState(() {
          _loadedImages[index] = response.bodyBytes;
          _loadingStates[index] = false;
        });
      } else {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loadingStates[index] = false;
        _errorStates[index] = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.imageUrls.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      body: widget.imageUrls.length > 1
          ? PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              physics: _isZoomed[_currentIndex] == true
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) {
                // Reset zoom of previous page
                final prevController = _transformationControllers[_currentIndex];
                if (prevController != null) {
                  prevController.value = Matrix4.identity();
                  _isZoomed[_currentIndex] = false;
                }
                
                setState(() {
                  _currentIndex = index;
                });
                _loadImage(index);
                // Pre-load adjacent images
                if (index > 0) _loadImage(index - 1);
                if (index < widget.imageUrls.length - 1) _loadImage(index + 1);
              },
              itemBuilder: (context, index) {
                return _buildImagePage(index);
              },
            )
          : _buildImagePage(0),
    );
  }

  Widget _buildImagePage(int index) {
    final imageBytes = _loadedImages[index];
    final isLoading = _loadingStates[index] ?? false;
    final error = _errorStates[index];

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadImage(index),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (imageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    // Ensure controller exists for this index
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
      _isZoomed[index] = false;
      _transformationControllers[index]!.addListener(() {
        if (mounted) {
          final matrix = _transformationControllers[index]!.value;
          final isZoomed = matrix.getMaxScaleOnAxis() > 1.01; // Use 1.01 to account for floating point precision
          if (_isZoomed[index] != isZoomed) {
            setState(() {
              _isZoomed[index] = isZoomed;
            });
          }
        }
      });
    }
    
    final controller = _transformationControllers[index]!;
    
    return InteractiveViewer(
      transformationController: controller,
      minScale: 0.5,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}


