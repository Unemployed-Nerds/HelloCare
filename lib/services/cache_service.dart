import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import '../models/appointment.dart';
import '../models/module_config.dart';
import 'dart:convert';

class CacheService {
  static const String reportsBoxName = 'reports';
  static const String appointmentsBoxName = 'appointments';
  static const String modulesBoxName = 'modules';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters if needed
    // For now, we'll use JSON serialization
  }

  // Reports Cache
  Future<void> cacheReports(List<Report> reports) async {
    final box = await Hive.openBox(reportsBoxName);
    final reportsJson = reports.map((r) => {
      'reportId': r.reportId,
      'userId': r.userId,
      'fileKey': r.fileKey,
      'fileName': r.fileName,
      'fileType': r.fileType,
      'title': r.title,
      'reportDate': r.reportDate.toIso8601String(),
      'category': r.category,
      'doctorName': r.doctorName,
      'clinicName': r.clinicName,
      'uploadDate': r.uploadDate.toIso8601String(),
      's3Url': r.s3Url,
      'extractedText': r.extractedText,
      'fileSize': r.fileSize,
    }).toList();
    await box.put('reports', jsonEncode(reportsJson));
  }

  Future<List<Report>> getCachedReports() async {
    try {
      final box = await Hive.openBox(reportsBoxName);
      final reportsJson = jsonDecode(box.get('reports', defaultValue: '[]') as String);
      return (reportsJson as List).map((json) {
        return Report(
          reportId: json['reportId'],
          userId: json['userId'],
          fileKey: json['fileKey'],
          fileName: json['fileName'],
          fileType: json['fileType'],
          title: json['title'],
          reportDate: DateTime.parse(json['reportDate']),
          category: json['category'],
          doctorName: json['doctorName'],
          clinicName: json['clinicName'],
          uploadDate: DateTime.parse(json['uploadDate']),
          s3Url: json['s3Url'],
          extractedText: json['extractedText'],
          fileSize: json['fileSize'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Appointments Cache
  Future<void> cacheAppointments(List<Appointment> appointments) async {
    final box = await Hive.openBox(appointmentsBoxName);
    final appointmentsJson = appointments.map((a) => {
      'appointmentId': a.appointmentId,
      'doctorId': a.doctorId,
      'doctorName': a.doctorName,
      'doctorSpecialization': a.doctorSpecialization,
      'patientId': a.patientId,
      'patientName': a.patientName,
      'date': a.date.toIso8601String(),
      'time': a.time,
      'duration': a.duration,
      'status': a.status,
      'notes': a.notes,
      'doctorNotes': a.doctorNotes,
      'createdAt': a.createdAt.toIso8601String(),
      'updatedAt': a.updatedAt?.toIso8601String(),
    }).toList();
    await box.put('appointments', jsonEncode(appointmentsJson));
  }

  Future<List<Appointment>> getCachedAppointments() async {
    try {
      final box = await Hive.openBox(appointmentsBoxName);
      final appointmentsJson = jsonDecode(box.get('appointments', defaultValue: '[]') as String);
      return (appointmentsJson as List).map((json) {
        return Appointment(
          appointmentId: json['appointmentId'],
          doctorId: json['doctorId'],
          doctorName: json['doctorName'],
          doctorSpecialization: json['doctorSpecialization'],
          patientId: json['patientId'],
          patientName: json['patientName'],
          date: DateTime.parse(json['date']),
          time: json['time'],
          duration: json['duration'],
          status: json['status'],
          notes: json['notes'],
          doctorNotes: json['doctorNotes'],
          createdAt: DateTime.parse(json['createdAt']),
          updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Module Configuration
  Future<void> savePinnedModules(List<ModuleConfig> modules) async {
    final prefs = await SharedPreferences.getInstance();
    final modulesJson = modules.map((m) => m.toMap()).toList();
    await prefs.setString('pinned_modules', jsonEncode(modulesJson));
  }

  Future<List<ModuleConfig>> getPinnedModules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modulesJson = prefs.getString('pinned_modules');
      if (modulesJson != null) {
        final decoded = jsonDecode(modulesJson) as List;
        return decoded.map((json) => ModuleConfig.fromMap(json)).toList();
      }
    } catch (e) {
      // Return default modules if error
    }
    return [];
  }

  // Clear cache
  Future<void> clearCache() async {
    final reportsBox = await Hive.openBox(reportsBoxName);
    final appointmentsBox = await Hive.openBox(appointmentsBoxName);
    await reportsBox.clear();
    await appointmentsBox.clear();
  }
}


