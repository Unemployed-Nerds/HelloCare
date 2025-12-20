import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class PDFViewer extends StatefulWidget {
  final String url;

  const PDFViewer({super.key, required this.url});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final documentFuture = PdfDocument.openData(bytes);
        _pdfController = PdfController(
          document: documentFuture,
          initialPage: 1,
        );
        
        // Get total pages by awaiting the document
        final document = await documentFuture;
        final totalPages = document.pagesCount;
        
        setState(() {
          _isLoading = false;
          _totalPages = totalPages;
          _currentPage = 1;
        });
      } else {
        setState(() {
          _error = 'Failed to load PDF';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_pdfController == null) {
      return const Center(child: Text('Failed to load PDF'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 570, // Leave space for page indicators
          child: PdfView(
            controller: _pdfController!,
            onPageChanged: (page) {
              if (mounted) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
          ),
        ),
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == (index + 1) ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == (index + 1)
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
}

