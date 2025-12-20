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
        _pdfController = PdfController(document: PdfDocument.openData(bytes));
        setState(() {
          _isLoading = false;
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

    return PdfView(
      controller: _pdfController!,
    );
  }
}

