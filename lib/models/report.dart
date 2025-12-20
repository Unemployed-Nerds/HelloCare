import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String reportId;
  final String userId;
  final String fileKey;
  final String fileName;
  final String fileType; // 'image' or 'pdf'
  final String title;
  final DateTime reportDate;
  final String? category;
  final String? doctorName;
  final String? clinicName;
  final DateTime uploadDate;
  final String? s3Url;
  final String? extractedText;
  final int? fileSize;

  Report({
    required this.reportId,
    required this.userId,
    required this.fileKey,
    required this.fileName,
    required this.fileType,
    required this.title,
    required this.reportDate,
    this.category,
    this.doctorName,
    this.clinicName,
    required this.uploadDate,
    this.s3Url,
    this.extractedText,
    this.fileSize,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to parse date from either Timestamp or ISO string
    DateTime _parseDate(dynamic dateValue) {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return Report(
      reportId: data['reportId'] ?? doc.id,
      userId: data['userId'] ?? '',
      fileKey: data['fileKey'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? '',
      title: data['title'] ?? '',
      reportDate: _parseDate(data['reportDate']),
      category: data['category'],
      doctorName: data['doctorName'],
      clinicName: data['clinicName'],
      uploadDate: _parseDate(data['uploadDate']),
      s3Url: data['s3Url'] ?? data['storageUrl'],
      extractedText: data['extractedText'],
      fileSize: data['fileSize'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fileKey': fileKey,
      'fileName': fileName,
      'fileType': fileType,
      'title': title,
      'reportDate': Timestamp.fromDate(reportDate),
      'category': category,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'uploadDate': Timestamp.fromDate(uploadDate),
      's3Url': s3Url,
      'extractedText': extractedText,
      'fileSize': fileSize,
    };
  }

  Report copyWith({
    String? reportId,
    String? userId,
    String? fileKey,
    String? fileName,
    String? fileType,
    String? title,
    DateTime? reportDate,
    String? category,
    String? doctorName,
    String? clinicName,
    DateTime? uploadDate,
    String? s3Url,
    String? extractedText,
    int? fileSize,
  }) {
    return Report(
      reportId: reportId ?? this.reportId,
      userId: userId ?? this.userId,
      fileKey: fileKey ?? this.fileKey,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      title: title ?? this.title,
      reportDate: reportDate ?? this.reportDate,
      category: category ?? this.category,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      uploadDate: uploadDate ?? this.uploadDate,
      s3Url: s3Url ?? this.s3Url,
      extractedText: extractedText ?? this.extractedText,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}


