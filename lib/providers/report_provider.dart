import 'package:flutter/foundation.dart';
import '../models/report.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/storage_service.dart';
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
      final uploadUrl = uploadUrlResponse['data']['uploadUrl'];

      print('Uploading file to: $uploadUrl');
      print('File key: $fileKey');
      print('File size: $fileSize bytes');
      print('Content type: $fileType');

      // Upload file to Firebase Storage using presigned URL
      final storageService = StorageService();
      try {
        await storageService.uploadToStorage(
          uploadUrl: uploadUrl,
          file: file,
          contentType: fileType,
        );
        print('File uploaded successfully to Firebase Storage');
      } catch (uploadError) {
        print('Error uploading file: $uploadError');
        throw Exception('Failed to upload file to storage: $uploadError');
      }

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

  Future<String?> getDownloadUrl(String reportId) async {
    try {
      final response = await _apiService.getDownloadUrl(reportId);
      print('Download URL response: $response');
      if (response['success'] == true && response['data'] != null) {
        final downloadUrl = response['data']['downloadUrl'] as String?;
        print('Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('Failed to get download URL: ${response['error']}');
        _error = response['error']?['message'] ?? 'Failed to get download URL';
        return null;
      }
    } catch (e) {
      print('Error getting download URL: $e');
      _error = e.toString();
      return null;
    }
  }

  Future<bool> deleteReport(String reportId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteReport(reportId);
      
      if (response['success'] == true) {
        // Remove from local list
        _reports.removeWhere((report) => report.reportId == reportId);
        // Update cache
        await _cacheService.cacheReports(_reports);
        _error = null;
        return true;
      } else {
        _error = response['error']?['message'] ?? 'Failed to delete report';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitMultipleImages({
    required String userId,
    required List<File> files,
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
      // Generate a group ID to link these images together
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      int successCount = 0;
      String? lastError;

      // Upload each image as a separate report
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        try {
          // Get file info
          final fileName = file.path.split('/').last;
          final fileType = fileName.toLowerCase().endsWith('.png') 
              ? 'image/png' 
              : 'image/jpeg';
          final fileSize = await file.length();

          // Get upload URL from backend
          final uploadUrlResponse = await _apiService.getUploadUrl(
            fileName: fileName,
            fileType: fileType,
            fileSize: fileSize,
          );

          if (!uploadUrlResponse['success']) {
            lastError = 'Failed to get upload URL for ${fileName}';
            continue;
          }

          final fileKey = uploadUrlResponse['data']['fileKey'];
          final uploadUrl = uploadUrlResponse['data']['uploadUrl'];

          // Upload file to Firebase Storage using presigned URL
          final storageService = StorageService();
          await storageService.uploadToStorage(
            uploadUrl: uploadUrl,
            file: file,
            contentType: fileType,
          );

          // Submit report metadata
          // Use base title for all images - they'll be grouped by title and date
          final reportResponse = await _apiService.submitReport({
            'fileKey': fileKey,
            'fileName': fileName,
            'fileType': 'image',
            'title': title,
            'reportDate': reportDate.toIso8601String().split('T')[0],
            'category': category,
            'doctorName': doctorName,
            'clinicName': clinicName,
          });

          if (reportResponse['success']) {
            successCount++;
          } else {
            lastError = 'Failed to submit ${fileName}';
          }
        } catch (e) {
          lastError = 'Error uploading ${file.path.split('/').last}: $e';
        }
      }

      if (successCount == 0) {
        _error = lastError ?? 'Failed to upload images';
        return false;
      }

      if (successCount < files.length) {
        _error = 'Uploaded $successCount of ${files.length} images. ${lastError ?? ''}';
      }

      // Reload reports
      await loadReports(userId);
      return successCount > 0;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

