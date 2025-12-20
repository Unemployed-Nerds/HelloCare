import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://hellocare.p1ng.me/v1';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors
        return handler.next(error);
      },
    ));
  }

  // Authentication
  Future<Map<String, dynamic>> patientSignup(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/patient/signup', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> patientLogin(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/patient/login', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> doctorSignup(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/doctor/signup', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> doctorLogin(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/doctor/login', data: data);
    return response.data;
  }

  // Reports
  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required String fileType,
    required int fileSize,
  }) async {
    final response = await _dio.post('/reports/upload-url', data: {
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> data) async {
    final response = await _dio.post('/reports', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 20,
    String? category,
    String? fileType,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (category != null) queryParams['category'] = category;
    if (fileType != null) queryParams['fileType'] = fileType;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get('/reports', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getReport(String reportId) async {
    final response = await _dio.get('/reports/$reportId');
    return response.data;
  }

  Future<Map<String, dynamic>> getDownloadUrl(String reportId) async {
    final response = await _dio.get('/reports/$reportId/download-url');
    return response.data;
  }

  Future<Map<String, dynamic>> exportReports({
    required List<String> reportIds,
    String format = 'zip',
  }) async {
    final response = await _dio.post('/reports/export', data: {
      'reportIds': reportIds,
      'format': format,
    });
    return response.data;
  }

  // AI Features
  Future<Map<String, dynamic>> getAISummary() async {
    final response = await _dio.get('/ai/summary');
    return response.data;
  }

  Future<Map<String, dynamic>> getAISuggestions({String? reportId}) async {
    final queryParams = reportId != null ? {'reportId': reportId} : null;
    final response = await _dio.get('/ai/suggestions', queryParameters: queryParams);
    return response.data;
  }

  // QR Code
  Future<Map<String, dynamic>> generateQRCode({
    required List<String> reportIds,
    int expiresIn = 3600,
  }) async {
    final response = await _dio.post('/reports/qr/generate', data: {
      'reportIds': reportIds,
      'expiresIn': expiresIn,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> validateQRToken(String qrToken) async {
    final response = await _dio.post('/reports/qr/validate', data: {
      'qrToken': qrToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getReportsByQRToken(String qrToken) async {
    final response = await _dio.get('/reports/qr/$qrToken');
    return response.data;
  }

  // Doctors
  Future<Map<String, dynamic>> getDoctors({
    String? specialization,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (specialization != null) queryParams['specialization'] = specialization;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get('/doctors', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getDoctor(String doctorId) async {
    final response = await _dio.get('/doctors/$doctorId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateDoctorAvailability({
    required String doctorId,
    required Map<String, dynamic> availability,
  }) async {
    final response = await _dio.put(
      '/doctors/$doctorId/availability',
      data: {'availability': availability},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    final response = await _dio.get(
      '/doctors/$doctorId/slots',
      queryParameters: {'date': date},
    );
    return response.data;
  }

  // Appointments
  Future<Map<String, dynamic>> bookAppointment(Map<String, dynamic> data) async {
    final response = await _dio.post('/appointments', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPatientAppointments({
    String? status,
    String? startDate,
    String? endDate,
    String? doctorId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (doctorId != null) queryParams['doctorId'] = doctorId;

    final response = await _dio.get(
      '/appointments/patient',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getDoctorAppointments({
    String? status,
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dio.get(
      '/appointments/doctor',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAppointment(String appointmentId) async {
    final response = await _dio.get('/appointments/$appointmentId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    final response = await _dio.put(
      '/appointments/$appointmentId/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addDoctorNotes({
    required String appointmentId,
    required String doctorNotes,
  }) async {
    final response = await _dio.put(
      '/appointments/$appointmentId/notes',
      data: {'doctorNotes': doctorNotes},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    final response = await _dio.delete('/appointments/$appointmentId');
    return response.data;
  }

  // Payment (Mock)
  Future<Map<String, dynamic>> processPayment(Map<String, dynamic> data) async {
    final response = await _dio.post('/payment/process', data: data);
    return response.data;
  }
}


