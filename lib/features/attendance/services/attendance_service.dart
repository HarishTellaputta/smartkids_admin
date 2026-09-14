import 'package:dio/dio.dart';

import '../models/attendance_request_model.dart';
import '../models/attendance_response_model.dart';
import '../models/attendance_report_model.dart';
import '../models/attendance_update_model.dart';
import '../models/bulk_attendance_request_model.dart';

class AttendanceService {
  final Dio _dio;

  AttendanceService(String token)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          ),
        );

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  Exception _handleError(DioException e) {
    String message = 'Something went wrong';

    if (e.response?.data != null) {
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        message = data['message']?.toString() ??
            data['error']?.toString() ??
            data.toString();
      } else {
        message = data.toString();
      }
    } else if (e.message != null) {
      message = e.message!;
    }

    return Exception(message);
  }

  // ============================================================
  // POST - MARK SINGLE ATTENDANCE
  // ============================================================

  Future<AttendanceResponseModel> markAttendance(
    AttendanceRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/attendances',
        data: request.toJson(),
      );

      return AttendanceResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // POST - BULK ATTENDANCE
  // ============================================================

  Future<List<AttendanceResponseModel>> markBulkAttendance(
    BulkAttendanceRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/v1/attendances/bulk',
        data: request.toJson(),
      );

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map(
            (item) => AttendanceResponseModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - ATTENDANCE BY ID
  // ============================================================

  Future<AttendanceResponseModel> getAttendanceById(
    int id,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/$id',
      );

      return AttendanceResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PUT - UPDATE ATTENDANCE
  // ============================================================

  Future<AttendanceResponseModel> updateAttendance(
    int id,
    AttendanceUpdateModel request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/attendances/$id',
        data: request.toJson(),
      );

      return AttendanceResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // DELETE - ATTENDANCE
  // ============================================================

  Future<void> deleteAttendance(
    int id,
  ) async {
    try {
      await _dio.delete(
        '/api/v1/attendances/$id',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - STUDENT ATTENDANCE
  // ============================================================

  Future<List<AttendanceResponseModel>> getStudentAttendance({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/student/$studentId',
        queryParameters: {
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      return _parseAttendanceList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - CLASS ATTENDANCE FOR DATE
  // ============================================================

  Future<List<AttendanceResponseModel>> getClassAttendance({
    required int classId,
    required DateTime date,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/class/$classId',
        queryParameters: {
          'date': _formatDate(date),
        },
      );

      return _parseAttendanceList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - CLASS ATTENDANCE DATE RANGE
  // ============================================================

  Future<List<AttendanceResponseModel>> getClassAttendanceByDateRange({
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/class/$classId/range',
        queryParameters: {
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      return _parseAttendanceList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - STUDENT ATTENDANCE REPORT
  // ============================================================

  Future<AttendanceReportModel> getStudentAttendanceReport({
    required int studentId,
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/student/$studentId/report',
        queryParameters: {
          'classId': classId,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      return AttendanceReportModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - CLASS ATTENDANCE REPORT
  // ============================================================

  Future<List<AttendanceReportModel>> getClassAttendanceReport({
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/class/$classId/report',
        queryParameters: {
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;

      return data
          .map(
            (item) => AttendanceReportModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - PARENT ATTENDANCE
  // ============================================================

  Future<List<AttendanceResponseModel>> getParentAttendance({
    required int parentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/parent/$parentId',
        queryParameters: {
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      return _parseAttendanceList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET - ATTENDANCE PERCENTAGE
  // ============================================================

  Future<double> calculateAttendancePercentage({
    required int studentId,
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/attendances/student/$studentId/percentage',
        queryParameters: {
          'classId': classId,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      if (response.data is num) {
        return (response.data as num).toDouble();
      }

      return double.tryParse(
            response.data.toString(),
          ) ??
          0.0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PARSE ATTENDANCE LIST
  // ============================================================

  List<AttendanceResponseModel> _parseAttendanceList(
    dynamic data,
  ) {
    if (data is! List) {
      return [];
    }

    return data
        .map(
          (item) => AttendanceResponseModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}