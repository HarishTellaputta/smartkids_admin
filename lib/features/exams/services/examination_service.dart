import 'package:dio/dio.dart';

import '../models/examination_model.dart';

class ExaminationService {
  final Dio _dio;

  ExaminationService(String token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  // ============================================================
  // CREATE EXAMINATION
  // POST /api/v1/examinations
  // ============================================================

  Future<ExaminationModel> createExamination({
    required int academicYearId,
    required String name,
    String? description,
    required String examType,
    required int year,
    required String status,
  }) async {
    try {
      final body = {
        'academicYearId': academicYearId,
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'examType': examType,
        'year': year,
        'status': status,
      };

      print('========================================');
      print('CREATE EXAMINATION');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.post('/api/v1/examinations', data: body);

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return ExaminationModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to create examination: $e');
    }
  }

  // ============================================================
  // UPDATE EXAMINATION
  // PUT /api/v1/examinations/{id}
  // ============================================================

  Future<ExaminationModel> updateExamination({
    required int id,
    required int academicYearId,
    required String name,
    String? description,
    required String examType,
    required int year,
    required String status,
  }) async {
    try {
      final body = {
        'academicYearId': academicYearId,
        'name': name.trim(),
        'description': description?.trim() ?? '',
        'examType': examType,
        'year': year,
        'status': status,
      };

      print('========================================');
      print('UPDATE EXAMINATION ID: $id');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.put('/api/v1/examinations/$id', data: body);

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return ExaminationModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to update examination: $e');
    }
  }

  // ============================================================
  // GET ALL EXAMINATIONS
  // GET /api/v1/examinations
  // ============================================================

  Future<List<ExaminationModel>> getExaminations() async {
    try {
      final response = await _dio.get('/api/v1/examinations');

      print('GET EXAMINATIONS STATUS: ${response.statusCode}');
      print('GET EXAMINATIONS RESPONSE: ${response.data}');

      return _parseExaminationList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load examinations: $e');
    }
  }

  // ============================================================
  // GET EXAMINATIONS BY ACADEMIC YEAR
  // GET /api/v1/examinations?academicYearId=1
  // ============================================================

  Future<List<ExaminationModel>> getExaminationsByAcademicYear(
    int academicYearId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/examinations',
        queryParameters: {'academicYearId': academicYearId},
      );

      return _parseExaminationList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load examinations by academic year: $e');
    }
  }

  // ============================================================
  // GET ALL SCHEDULES
  // GET /api/v1/examinations/schedules
  // ============================================================

  Future<List<ExamScheduleModel>> getSchedules() async {
    try {
      final response = await _dio.get('/api/v1/examinations/schedules');

      return _parseScheduleList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load exam schedules: $e');
    }
  }

  // ============================================================
  // GET SCHEDULES BY EXAMINATION
  // GET /api/v1/examinations/schedules?examinationId=1
  // ============================================================

  Future<List<ExamScheduleModel>> getSchedulesByExamination(
    int examinationId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/examinations/schedules',
        queryParameters: {'examinationId': examinationId},
      );

      print('SCHEDULES FOR EXAM $examinationId: ${response.data}');

      return _parseScheduleList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load examination schedules: $e');
    }
  }

  // ============================================================
  // CREATE EXAM SCHEDULE
  // POST /api/v1/examinations/schedules
  // ============================================================

  Future<ExamScheduleModel> createSchedule({
    required int examinationId,
    required int classId,
    int? sectionId,
    int? subjectTeacherId,
    required String subject,
    required String examDate,
    required String startTime,
    required int duration,
    required int maxMarks,
    required String examType,
    String? roomNumber,
    required String status,
  }) async {
    try {
      final body = {
        'examinationId': examinationId,
        'classId': classId,
        'sectionId': sectionId,
        'subjectTeacherId': subjectTeacherId,
        'subject': subject.trim(),
        'examDate': examDate,
        'startTime': startTime,
        'duration': duration,
        'maxMarks': maxMarks,
        'examType': examType,
        'roomNumber': roomNumber?.trim() ?? '',
        'status': status,
      };

      final response = await _dio.post(
        '/api/v1/examinations/schedules',
        data: body,
      );

      return ExamScheduleModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to create exam schedule: $e');
    }
  }

  // ============================================================
  // UPDATE EXAM SCHEDULE
  // PUT /api/v1/examinations/schedules/{id}
  // ============================================================

  Future<ExamScheduleModel> updateSchedule({
    required int id,
    required int examinationId,
    required int classId,
    int? sectionId,
    int? subjectTeacherId,
    required String subject,
    required String examDate,
    required String startTime,
    required int duration,
    required int maxMarks,
    required String examType,
    String? roomNumber,
    required String status,
  }) async {
    try {
      final body = {
        'examinationId': examinationId,
        'classId': classId,
        'sectionId': sectionId,
        'subjectTeacherId': subjectTeacherId,
        'subject': subject.trim(),
        'examDate': examDate,
        'startTime': startTime,
        'duration': duration,
        'maxMarks': maxMarks,
        'examType': examType,
        'roomNumber': roomNumber?.trim() ?? '',
        'status': status,
      };

      final response = await _dio.put(
        '/api/v1/examinations/schedules/$id',
        data: body,
      );

      return ExamScheduleModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to update exam schedule: $e');
    }
  }

  // ============================================================
  // PARSERS
  // ============================================================

  List<ExaminationModel> _parseExaminationList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
                ExaminationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        return content
            .whereType<Map>()
            .map(
              (item) =>
                  ExaminationModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    return [];
  }

  List<ExamScheduleModel> _parseScheduleList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
                ExamScheduleModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        return content
            .whereType<Map>()
            .map(
              (item) =>
                  ExamScheduleModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (status) {
      case 400:
        return 'Invalid examination data.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Examination not found.';
      case 409:
        return 'This examination already exists.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}
