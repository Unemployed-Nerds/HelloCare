import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final Dio _dio = Dio();

  // Upload file to Firebase Storage using presigned URL
  Future<void> uploadToStorage({
    required String uploadUrl,
    required File file,
    String? contentType,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      // Read file bytes
      final fileBytes = await file.readAsBytes();
      print('File bytes read: ${fileBytes.length} bytes');
      
      // Use PUT request with file bytes and proper content type
      // Note: Firebase Storage presigned URLs require specific headers
      final response = await _dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {
            if (contentType != null) 'Content-Type': contentType,
            // Don't add Authorization header - presigned URLs are self-contained
          },
          validateStatus: (status) {
            // Accept 200 and 201 as success
            return status != null && status >= 200 && status < 300;
          },
        ),
        onSendProgress: onProgress,
      );
      
      print('Upload response status: ${response.statusCode}');
      print('Upload response headers: ${response.headers}');
      
      if (response.statusCode == null || 
          (response.statusCode! < 200 || response.statusCode! >= 300)) {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
      
      print('File uploaded successfully');
    } catch (e) {
      print('Error in uploadToStorage: $e');
      rethrow;
    }
  }

  // Legacy method name for backward compatibility
  Future<void> uploadToS3({
    required String uploadUrl,
    required File file,
    Function(int sent, int total)? onProgress,
  }) async {
    await uploadToStorage(
      uploadUrl: uploadUrl,
      file: file,
      onProgress: onProgress,
    );
  }

  // Download file from Firebase Storage
  Future<File> downloadFromStorage({
    required String downloadUrl,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/$fileName';

    await _dio.download(
      downloadUrl,
      filePath,
      onReceiveProgress: onProgress,
    );

    return File(filePath);
  }

  // Legacy method name for backward compatibility
  Future<File> downloadFromS3({
    required String downloadUrl,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    return downloadFromStorage(
      downloadUrl: downloadUrl,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  // Save file locally
  Future<File> saveFileLocally({
    required File sourceFile,
    required String fileName,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final destinationPath = '${appDir.path}/$fileName';
    return await sourceFile.copy(destinationPath);
  }

  // Get local file path
  Future<String> getLocalFilePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$fileName';
  }

  // Check if file exists locally
  Future<bool> fileExistsLocally(String fileName) async {
    final filePath = await getLocalFilePath(fileName);
    return File(filePath).existsSync();
  }

  // Delete local file
  Future<void> deleteLocalFile(String fileName) async {
    final filePath = await getLocalFilePath(fileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}


