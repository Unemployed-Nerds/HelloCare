import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../widgets/pdf_viewer.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  const ReportDetailPage({super.key, required this.reportId});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  String? _downloadUrl;
  bool _isLoadingUrl = false;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDownloadUrl();
    });
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

        return Scaffold(
          backgroundColor: AppTheme.backgroundGreen,
          appBar: AppBar(
            title: Text(report.title),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (report.category != null)
                          Text('Category: ${report.category}'),
                        if (report.doctorName != null)
                          Text('Doctor: ${report.doctorName}'),
                        if (report.clinicName != null)
                          Text('Clinic: ${report.clinicName}'),
                        Text('Report Date: ${report.reportDate.toString().split(' ')[0]}'),
                        Text('Uploaded: ${report.uploadDate.toString().split(' ')[0]}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                  SizedBox(
                    height: 600,
                    child: PDFViewer(url: _downloadUrl!),
                  )
                else
                  _ImageWidget(downloadUrl: _downloadUrl!, onRetry: _loadDownloadUrl),
              ],
            ),
          ),
        );
      },
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


