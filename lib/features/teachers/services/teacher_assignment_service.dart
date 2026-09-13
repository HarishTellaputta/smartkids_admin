import 'package:dio/dio.dart';

import '../models/teacher_assignment_model.dart';

class TeacherAssignmentService {
  final Dio _dio;

  TeacherAssignmentService(String token)
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
  // CREATE TEACHER CLASS ASSIGNMENT
  //
  // POST /api/v1/teacher-class-assignments
  //
  // Body:
  // {
  //   "teacherId": 1,
  //   "classId": 1,
  //   "subject": "Mathematics"
  // }
  // ============================================================

  Future<TeacherAssignment> createAssignment({
    required int teacherId,
    required int classId,
    required String subject,
  }) async {
    try {
      final body = {
        'teacherId': teacherId,
        'classId': classId,
        'subject': subject,
      };

      final response = await _dio.post(
        '/api/v1/teacher-class-assignments',
        data: body,
      );

      return TeacherAssignment.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to assign teacher: $e',
      );
    }
  }

  // ============================================================
  // GET ASSIGNMENT BY ID
  //
  // GET /api/v1/teacher-class-assignments/{id}
  // ============================================================

  Future<TeacherAssignment> getAssignmentById(
    int id,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-class-assignments/$id',
      );

      return TeacherAssignment.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load assignment: $e',
      );
    }
  }

  // ============================================================
  // GET ASSIGNMENTS BY TEACHER
  //
  // GET /api/v1/teacher-class-assignments/teacher/{teacherId}
  // ============================================================

  Future<List<TeacherAssignment>> getAssignmentsByTeacher(
    int teacherId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-class-assignments/teacher/$teacherId',
      );

      return _parseAssignmentList(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load teacher assignments: $e',
      );
    }
  }

  // ============================================================
  // GET ASSIGNMENTS BY CLASS
  //
  // GET /api/v1/teacher-class-assignments/class/{classId}
  // ============================================================

  Future<List<TeacherAssignment>> getAssignmentsByClass(
    int classId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-class-assignments/class/$classId',
      );

      return _parseAssignmentList(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load class assignments: $e',
      );
    }
  }

  // ============================================================
  // GET ASSIGNMENTS BY TEACHER + SUBJECT
  //
  // GET
  // /api/v1/teacher-class-assignments/teacher/{teacherId}/subject/{subject}
  // ============================================================

  Future<List<TeacherAssignment>> getAssignmentsByTeacherAndSubject({
    required int teacherId,
    required String subject,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-class-assignments/teacher/$teacherId/subject/${Uri.encodeComponent(subject)}',
      );

      return _parseAssignmentList(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load subject assignments: $e',
      );
    }
  }

  // ============================================================
  // GET SUBJECTS ASSIGNED TO TEACHER
  //
  // GET /api/v1/teacher-class-assignments/teacher/{teacherId}/subjects
  //
  // Backend response may be:
  // ["Mathematics", "Science"]
  // ============================================================

  Future<List<String>> getSubjectsByTeacher(
    int teacherId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-class-assignments/teacher/$teacherId/subjects',
      );

      final data = response.data;

      if (data is List) {
        return data
            .map((item) => item.toString())
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load teacher subjects: $e',
      );
    }
  }

  // ============================================================
  // DELETE ASSIGNMENT
  //
  // DELETE /api/v1/teacher-class-assignments/{id}
  // ============================================================

  Future<void> deleteAssignment(int id) async {
    try {
      await _dio.delete(
        '/api/v1/teacher-class-assignments/$id',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to remove assignment: $e',
      );
    }
  }

  // ============================================================
  // PARSE ASSIGNMENT LIST
  // ============================================================

  List<TeacherAssignment> _parseAssignmentList(
    dynamic data,
  ) {
    if (data is List) {
      return data
          .map(
            (json) => TeacherAssignment.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    }

    // Supports Spring Page response:
    //
    // {
    //   "content": [...]
    // }

    if (data is Map<String, dynamic> &&
        data['content'] is List) {
      return (data['content'] as List)
          .map(
            (json) => TeacherAssignment.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleDioError(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      if (statusCode == 400) {
        return 'Bad request. Please check the assignment details.';
      }

      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (statusCode == 403) {
        return 'Access denied. You do not have permission.';
      }

      if (statusCode == 404) {
        return 'Assignment not found.';
      }

      if (statusCode == 409) {
        return 'This teacher is already assigned to this class and subject.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      if (response.data is Map &&
          response.data['message'] != null) {
        return response.data['message'].toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check the server.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout.';

      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Make sure Spring Boot is running.';

      case DioExceptionType.badResponse:
        return 'Server returned an error.';

      default:
        return error.message ?? 'Something went wrong.';
    }
  }
}