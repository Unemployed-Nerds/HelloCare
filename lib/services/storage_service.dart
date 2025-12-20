import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final Dio _dio = Dio();

  // Upload file to S3 using presigned URL
  Future<void> uploadToS3({
    required String uploadUrl,
    required File file,
    Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    await _dio.put(
      uploadUrl,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
      onSendProgress: onProgress,
    );
  }

  // Download file from S3
  Future<File> downloadFromS3({
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


