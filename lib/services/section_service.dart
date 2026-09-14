import 'package:dio/dio.dart';
import '../models/section_model.dart';

class SectionService {
  final Dio _dio;

  SectionService(String token)
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
  // GET ALL SECTIONS
  // ============================================================

  Future<List<Section>> getSections() async {
    try {
      final response = await _dio.get(
        '/api/v1/sections',
      );

      return _parseSectionList(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load sections: $e');
    }
  }

  // ============================================================
  // GET SECTION BY ID
  // ============================================================

  Future<Section> getSectionById(int id) async {
    try {
      final response = await _dio.get(
        '/api/v1/sections/$id',
      );

      return Section.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load section: $e');
    }
  }

  // ============================================================
  // GET SECTIONS BY CLASS ID
  // ============================================================

  Future<List<Section>> getSectionsByClassId(int classId) async {
    try {
      final response = await _dio.get(
        '/api/v1/sections/class/$classId',
      );

      return _parseSectionList(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Failed to load sections for class: $e',
      );
    }
  }

  // ============================================================
  // CREATE SECTION
  // ============================================================

  Future<Section> createSection({
    required int classId,
    required String name,
    int? capacity,
    String? description,
  }) async {
    try {
      final body = {
        'classId': classId,
        'name': name,
        'capacity': capacity,
        'description': description,
      };

      final response = await _dio.post(
        '/api/v1/sections',
        data: body,
      );

      return Section.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to create section: $e');
    }
  }

  // ============================================================
  // UPDATE SECTION
  // ============================================================

  Future<Section> updateSection({
    required int id,
    required int classId,
    required String name,
    int? capacity,
    String? description,
  }) async {
    try {
      final body = {
        'classId': classId,
        'name': name,
        'capacity': capacity,
        'description': description,
      };

      final response = await _dio.put(
        '/api/v1/sections/$id',
        data: body,
      );

      return Section.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to update section: $e');
    }
  }

  // ============================================================
  // DELETE SECTION
  // ============================================================

  Future<void> deleteSection(int id) async {
    try {
      await _dio.delete(
        '/api/v1/sections/$id',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to delete section: $e');
    }
  }

  // ============================================================
  // PARSE LIST
  // ============================================================

  List<Section> _parseSectionList(dynamic data) {
    if (data is List) {
      return data
          .map(
            (json) => Section.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        return (data['content'] as List)
            .map(
              (json) => Section.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      if (data['data'] is List) {
        return (data['data'] as List)
            .map(
              (json) => Section.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _handleDioError(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      if (statusCode == 400) {
        return 'Bad request. Please check the entered data.';
      }

      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (statusCode == 403) {
        return 'Access denied. You do not have permission.';
      }

      if (statusCode == 404) {
        return 'Section not found.';
      }

      if (statusCode == 409) {
        return 'Section already exists.';
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