import 'package:dio/dio.dart';
import '../models/timetable_model.dart';

class TimetableService {
  final Dio _dio;

  TimetableService(String token)
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
  // CREATE
  // ============================================================

  Future<TimetableEntry> createTimetable({
    required int teacherId,
    required int classId,
    int? sectionId,
    required String subject,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomNumber,
  }) async {
    try {
      final body = {
        'teacherId': teacherId,
        'classId': classId,
        'sectionId': sectionId,
        'subject': subject,
        'dayOfWeek': dayOfWeek,
        'startTime': _toBackendTime(startTime),
        'endTime': _toBackendTime(endTime),
        'roomNumber': roomNumber,
      };

      final response = await _dio.post(
        '/api/v1/teacher-timetables',
        data: body,
      );

      return TimetableEntry.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TimetableEntry> getTimetableById(int id) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-timetables/$id',
      );

      return TimetableEntry.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY TEACHER
  // ============================================================

  Future<List<TimetableEntry>> getByTeacher(int teacherId) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-timetables/teacher/$teacherId',
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY TEACHER + DAY
  // ============================================================

  Future<List<TimetableEntry>> getByTeacherAndDay(
    int teacherId,
    String day,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-timetables/teacher/$teacherId/day/$day',
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY CLASS
  // ============================================================

  Future<List<TimetableEntry>> getByClass(int classId) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-timetables/class/$classId',
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY STUDENT
  // ============================================================

  Future<List<TimetableEntry>> getByStudent(int studentId) async {
    try {
      final response = await _dio.get(
        '/api/v1/teacher-timetables/student/$studentId',
      );

      return _parseList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<TimetableEntry> updateTimetable({
    required int id,
    required int teacherId,
    required int classId,
    int? sectionId,
    required String subject,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomNumber,
  }) async {
    try {
      final body = {
        'teacherId': teacherId,
        'classId': classId,
        'sectionId': sectionId,
        'subject': subject,
        'dayOfWeek': dayOfWeek,
        'startTime': _toBackendTime(startTime),
        'endTime': _toBackendTime(endTime),
        'roomNumber': roomNumber,
      };

      final response = await _dio.put(
        '/api/v1/teacher-timetables/$id',
        data: body,
      );

      return TimetableEntry.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteTimetable(int id) async {
    try {
      await _dio.delete(
        '/api/v1/teacher-timetables/$id',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<TimetableEntry> _parseList(dynamic data) {
    if (data is List) {
      return data
          .map(
            (json) => TimetableEntry.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        return (data['content'] as List)
            .map(
              (json) => TimetableEntry.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      if (data['data'] is List) {
        return (data['data'] as List)
            .map(
              (json) => TimetableEntry.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }
    }

    return [];
  }

  String _toBackendTime(String time) {
    if (time.length == 5) {
      return '$time:00';
    }

    return time;
  }

  String _handleError(DioException error) {
    final response = error.response;

    if (response != null) {
      final status = response.statusCode;

      if (response.data is Map &&
          response.data['message'] != null) {
        return response.data['message'].toString();
      }

      if (response.data is String &&
          (response.data as String).isNotEmpty) {
        return response.data.toString();
      }

      if (status == 400) {
        return 'Invalid timetable data.';
      }

      if (status == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (status == 403) {
        return 'You do not have permission.';
      }

      if (status == 404) {
        return 'Timetable not found.';
      }

      if (status == 409) {
        return 'Timetable conflict. Teacher or class already has another period at this time.';
      }

      if (status != null && status >= 500) {
        return 'Server error. Please try again later.';
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout.';

      case DioExceptionType.connectionError:
        return 'Cannot connect to Spring Boot server.';

      case DioExceptionType.badResponse:
        return 'Server returned an error.';

      default:
        return error.message ?? 'Something went wrong.';
    }
  }
}