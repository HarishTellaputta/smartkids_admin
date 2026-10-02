import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

import '../models/attendance_report_model.dart';
import '../models/examination_report_model.dart';
import '../models/fee_report_model.dart';
import '../models/academic_performance_model.dart';
import '../../reports/models/academic_performance_model.dart';
import '../../reports/models/examination_report_model.dart';
import '../models/mcq_performance_model.dart';

class ReportService {
  final ApiClient apiClient;

  ReportService(this.apiClient);

  // ============================================================
  // ATTENDANCE REPORT
  // GET /api/v1/reports/attendance
  // ============================================================

  Future<List<AttendanceReportModel>> getAttendanceReport({
    required String from,
    required String to,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/attendance',
        queryParameters: {'from': from, 'to': to, 'page': page, 'size': size},
      );

      return _parseList(response.data, AttendanceReportModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load attendance report: $e');
    }
  }

  // ============================================================
  // EXAMINATION REPORT
  // GET /api/v1/reports/examinations
  // ============================================================

  Future<List<ExaminationReportModel>> getExaminationReport({
    required String from,
    required String to,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/examinations',
        queryParameters: {'from': from, 'to': to, 'page': page, 'size': size},
      );

      return _parseList(response.data, ExaminationReportModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load examination report: $e');
    }
  }

  // ============================================================
  // FEE REPORT
  // GET /api/v1/reports/fees
  // ============================================================

  Future<FeeReportPage> getFeeReport({
    required String from,
    required String to,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/fees',
        queryParameters: {'from': from, 'to': to, 'page': page, 'size': size},
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        final content = data['content'];

        final items = content is List
            ? content
                  .whereType<Map>()
                  .map(
                    (item) => FeeReportModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
            : <FeeReportModel>[];

        return FeeReportPage(
          items: items,
          totalElements: _toInt(data['totalElements']),
          totalPages: _toInt(data['totalPages']),
          currentPage: _toInt(data['number']),
          pageSize: _toInt(data['size']),
          first: data['first'] == true,
          last: data['last'] == true,
        );
      }

      // Fallback if backend ever returns a direct List
      if (data is List) {
        final items = data
            .whereType<Map>()
            .map(
              (item) =>
                  FeeReportModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        return FeeReportPage(
          items: items,
          totalElements: items.length,
          totalPages: items.isEmpty ? 1 : 1,
          currentPage: 0,
          pageSize: items.length,
          first: true,
          last: true,
        );
      }

      throw Exception('Invalid fee report response.');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load fee report: $e');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  // ============================================================
  // ACADEMIC PERFORMANCE
  // GET /api/v1/reports/academic-performance
  // ============================================================

  Future<List<AcademicPerformanceModel>> getAcademicPerformance({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/academic-performance',
        queryParameters: {'page': page, 'size': size},
      );

      return _parseList(response.data, AcademicPerformanceModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load academic performance: $e');
    }
  }

  // ============================================================
  // STUDENT PERFORMANCE
  // GET /api/v1/reports/student-performance/{studentId}
  // ============================================================

  Future<List<AcademicPerformanceModel>> getStudentPerformance({
    required int studentId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/student-performance/$studentId',
        queryParameters: {'page': page, 'size': size},
      );

      return _parseList(response.data, AcademicPerformanceModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load student performance: $e');
    }
  }

  // ============================================================
  // CLASS PERFORMANCE
  // GET /api/v1/reports/teacher-class-performance/{classId}
  // ============================================================

  Future<List<ExaminationReportModel>> getClassPerformance({
    required int classId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/reports/teacher-class-performance/$classId',
        queryParameters: {'page': page, 'size': size},
      );

      return _parseList(response.data, ExaminationReportModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load class performance: $e');
    }
  }

  // ============================================================
  // MCQ PERFORMANCE
  // GET /api/v1/reports/mcq-performance
  // ============================================================
  // ============================================================
  // MCQ PERFORMANCE
  // GET /api/v1/reports/mcq-performance
  // ============================================================

  Future<List<McqPerformanceModel>> getMcqPerformance({
    String? date,
    int? classId,
    int? sectionId,
    String? subject,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {'page': page, 'size': size};

      // Optional filters
      if (date != null && date.trim().isNotEmpty) {
        queryParameters['date'] = date;
      }

      if (classId != null) {
        queryParameters['classId'] = classId;
      }

      if (sectionId != null) {
        queryParameters['sectionId'] = sectionId;
      }

      if (subject != null && subject.trim().isNotEmpty) {
        queryParameters['subject'] = subject.trim();
      }

      final response = await apiClient.dio.get(
        '/api/v1/reports/mcq-performance',
        queryParameters: queryParameters,
      );

      return _parseList(response.data, McqPerformanceModel.fromJson);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load MCQ performance: $e');
    }
  }
  // ============================================================
  // GENERIC PAGINATED LIST PARSER
  // ============================================================

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    List<dynamic> items = [];

    // Spring Boot Page response
    //
    // {
    //   "content": [...]
    // }
    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        items = content;
      }
    }
    // Direct List response
    else if (data is List) {
      items = data;
    }

    return items
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
        return 'Invalid report request.';

      case 401:
        return 'Session expired. Please login again.';

      case 403:
        return 'You do not have permission to view this report.';

      case 404:
        return 'Report data not found.';

      case 500:
        return 'Server error. Please try again.';

      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}
class FeeReportPage {
  final List<FeeReportModel> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool first;
  final bool last;

  const FeeReportPage({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.first,
    required this.last,
  });
}