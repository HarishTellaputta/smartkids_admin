import 'package:dio/dio.dart';

import '../models/academic_year_model.dart';

class AcademicYearService {
  final Dio _dio;

  AcademicYearService(String token)
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
  // GET ALL ACADEMIC YEARS
  // GET /api/v1/academic-years
  // ============================================================

  Future<List<AcademicYear>> getAcademicYears() async {
    try {
      final response = await _dio.get('/api/v1/academic-years');

      final data = response.data;

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map((json) => AcademicYear.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load academic years: $e');
    }
  }

  // ============================================================
  // GET CURRENT ACADEMIC YEAR
  // GET /api/v1/academic-years/current
  // ============================================================

  Future<AcademicYear?> getCurrentAcademicYear() async {
    try {
      final response = await _dio.get('/api/v1/academic-years/current');

      if (response.statusCode == 200 && response.data is Map) {
        return AcademicYear.fromJson(Map<String, dynamic>.from(response.data));
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load current academic year: $e');
    }
  }

  // ============================================================
  // GET ACADEMIC YEAR BY ID
  // GET /api/v1/academic-years/{id}
  // ============================================================

  Future<AcademicYear> getAcademicYearById(int id) async {
    try {
      final response = await _dio.get('/api/v1/academic-years/$id');

      return AcademicYear.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load academic year: $e');
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleError(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      if (response.data is Map && response.data['message'] != null) {
        return response.data['message'].toString();
      }

      if (statusCode == 400) {
        return 'Bad request. Please check the data.';
      }

      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (statusCode == 403) {
        return 'Access denied. You do not have permission.';
      }

      if (statusCode == 404) {
        return 'Academic year not found.';
      }

      if (statusCode == 409) {
        return 'Academic year already exists.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
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
