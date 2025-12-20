import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'dart:io';

class ReportProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  List<Report> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReportProvider() {
    _init();
  }

  Future<void> _init() async {
    await CacheService.init();
  }

  Future<void> loadReports(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from Firestore
      _reports = await _firestoreService.getReports(userId);
      // Cache the reports
      await _cacheService.cacheReports(_reports);
      _error = null;
    } catch (e) {
      // If online fails, try cache
      try {
        _reports = await _cacheService.getCachedReports();
        _error = 'Using cached data. Please check your connection.';
      } catch (cacheError) {
        _error = e.toString();
        _reports = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Report>> getReportsStream(String userId) {
    return _firestoreService.getReportsStream(userId);
  }

  Future<bool> submitReport({
    required String userId,
    required File file,
    required String title,
    required DateTime reportDate,
    String? category,
    String? doctorName,
    String? clinicName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get file info
      final fileName = file.path.split('/').last;
      final fileType = fileName.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
      final fileSize = await file.length();

      // Get upload URL from backend
      final uploadUrlResponse = await _apiService.getUploadUrl(
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
      );

      if (!uploadUrlResponse['success']) {
        throw Exception('Failed to get upload URL');
      }

      final fileKey = uploadUrlResponse['data']['fileKey'];

      // Upload to S3 (this would need storage service)
      // For now, we'll assume the backend handles it
      // In a real implementation, you'd upload the file here

      // Submit report metadata
      final reportResponse = await _apiService.submitReport({
        'fileKey': fileKey,
        'fileName': fileName,
        'fileType': fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
        'title': title,
        'reportDate': reportDate.toIso8601String().split('T')[0],
        'category': category,
        'doctorName': doctorName,
        'clinicName': clinicName,
      });

      if (!reportResponse['success']) {
        throw Exception('Failed to submit report');
      }

      // Reload reports
      await loadReports(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Report?> getReport(String reportId) async {
    try {
      return await _firestoreService.getReport(reportId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

