import 'package:dio/dio.dart';
import '../models/exam_schedule_model.dart';
import '../models/examination_model.dart';
import '../models/grade_rule_model.dart';
import '../models/exam_result_model.dart';

import 'package:smartkids_admin/features/teachers/models/teacher_performance_model.dart';

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
  // GET SCHEDULES
  // GET /api/v1/examinations/schedules
  // Supports examinationId, classId, sectionId, subjectId
  // ============================================================

  Future<List<ExamScheduleModel>> getSchedules({
    int? examinationId,
    int? classId,
    int? sectionId,
    int? subjectId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (examinationId != null) {
        queryParameters['examinationId'] = examinationId;
      }

      if (classId != null) {
        queryParameters['classId'] = classId;
      }

      if (sectionId != null) {
        queryParameters['sectionId'] = sectionId;
      }

      if (subjectId != null) {
        queryParameters['subjectId'] = subjectId;
      }

      final response = await _dio.get(
        '/api/v1/examinations/schedules',
        queryParameters: queryParameters,
      );

      print('========================================');
      print('GET EXAM SCHEDULES');
      print('QUERY: $queryParameters');
      print('RESPONSE: ${response.data}');
      print('========================================');

      return _parseScheduleList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load exam schedules: $e');
    }
  }

  // ============================================================
  // GET SCHEDULES BY EXAMINATION
  // ============================================================

  Future<List<ExamScheduleModel>> getSchedulesByExamination(
    int examinationId, {
    int? classId,
    int? sectionId,
    int? subjectId,
  }) async {
    return getSchedules(
      examinationId: examinationId,
      classId: classId,
      sectionId: sectionId,
      subjectId: subjectId,
    );
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
    required int subjectId,
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
        'subjectId': subjectId,
        'examDate': examDate,
        'startTime': startTime,
        'duration': duration,
        'maxMarks': maxMarks,
        'examType': examType,
        'roomNumber': roomNumber?.trim() ?? '',
        'status': status,
      };

      print('========================================');
      print('CREATE EXAM SCHEDULE');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.post(
        '/api/v1/examinations/schedules',
        data: body,
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

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
    required int subjectId,
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
        'subjectId': subjectId,
        'examDate': examDate,
        'startTime': startTime,
        'duration': duration,
        'maxMarks': maxMarks,
        'examType': examType,
        'roomNumber': roomNumber?.trim() ?? '',
        'status': status,
      };

      print('========================================');
      print('UPDATE EXAM SCHEDULE ID: $id');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.put(
        '/api/v1/examinations/schedules/$id',
        data: body,
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

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

  Future<List<ExamResultResponseModel>> getResultsByStudent(
    int studentId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/examinations/results',
        queryParameters: {'studentId': studentId},
      );

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map(
              (item) => ExamResultResponseModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<TeacherPerformance>> getTeacherPerformance(int teacherId) async {
    final response = await _dio.get('/api/v1/teachers/$teacherId/performance');

    final data = response.data;

    if (data is List) {
      return data
          .map(
            (json) =>
                TeacherPerformance.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    }

    return [];
  }

  // ============================================================
  // IMPORT EXAMINATIONS FROM EXCEL
  // POST /api/v1/examinations/import
  // ============================================================

  // ============================================================
  // GET GRADE RULES
  // GET /api/v1/examinations/grade-rules
  // ============================================================

  Future<List<GradeRuleModel>> getGradeRules() async {
    try {
      final response = await _dio.get('/api/v1/examinations/grade-rules');

      print('========================================');
      print('GET GRADE RULES');
      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');
      print('========================================');

      return _parseGradeRuleList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load grade rules: $e');
    }
  }

  // ============================================================
  // CREATE GRADE RULE
  // POST /api/v1/examinations/grade-rules
  // ============================================================

  Future<GradeRuleModel> createGradeRule({
    required String grade,
    required double minimumPercentage,
    required double maximumPercentage,
  }) async {
    try {
      final body = {
        'grade': grade.trim(),
        'minimumPercentage': minimumPercentage,
        'maximumPercentage': maximumPercentage,
      };

      print('========================================');
      print('CREATE GRADE RULE');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.post(
        '/api/v1/examinations/grade-rules',
        data: body,
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return GradeRuleModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to create grade rule: $e');
    }
  }

  List<GradeRuleModel> _parseGradeRuleList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => GradeRuleModel.fromJson(Map<String, dynamic>.from(item)),
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
                  GradeRuleModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      final dataList = data['data'];

      if (dataList is List) {
        return dataList
            .whereType<Map>()
            .map(
              (item) =>
                  GradeRuleModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    return [];
  }

  Future<List<ExamResultResponseModel>> getResults({
    int? scheduleId,
    int? studentId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/examinations/results',
        queryParameters: {
          if (scheduleId != null) 'scheduleId': scheduleId,
          if (studentId != null) 'studentId': studentId,
        },
      );

      final data = response.data;

      if (data is List) {
        return data
            .map(
              (e) => ExamResultResponseModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load examination results',
      );
    }
  }

  Future<ExamResultResponseModel> setResultPublication({
    required int id,
    required bool published,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/v1/examinations/results/$id/publish',
        queryParameters: {'published': published},
      );

      return ExamResultResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to update result publication',
      );
    }
  }

  // ============================================================
  // PUBLISH / UNPUBLISH ALL RESULTS FOR AN EXAMINATION
  // PATCH /api/v1/examinations/{examinationId}/results/publish
  // ============================================================

  Future<List<ExamResultResponseModel>> setExaminationResultsPublication({
    required int examinationId,
    required bool published,
  }) async {
    try {
      print('========================================');
      print('EXAMINATION RESULT PUBLICATION');
      print('EXAMINATION ID: $examinationId');
      print('PUBLISHED: $published');
      print('========================================');

      final response = await _dio.patch(
        '/api/v1/examinations/$examinationId/results/publish',
        queryParameters: {'published': published},
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      final data = response.data;

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => ExamResultResponseModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to update examination result publication',
      );
    } catch (e) {
      throw Exception('Failed to update examination result publication: $e');
    }
  }
}
