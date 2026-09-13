
import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class AdminDashboardService {
  final ApiClient apiClient;

  AdminDashboardService(this.apiClient);

  // =========================
  // STUDENTS
  // =========================

  Future<int> getStudentCount() async {
    try {
      final response = await apiClient.dio.get(
        '/students',
      );

      print('STUDENTS RESPONSE: ${response.data}');

      // Backend returns Spring Page response:
      //
      // {
      //   "content": [...],
      //   "totalElements": 9,
      //   "totalPages": 2,
      //   ...
      // }

      final totalElements = response.data['totalElements'];

      if (totalElements == null) {
        return 0;
      }

      return (totalElements as num).toInt();
    } on DioException catch (e) {
      print('STUDENT COUNT ERROR: ${e.response?.data}');
      print('STUDENT COUNT STATUS: ${e.response?.statusCode}');

      throw Exception(
        'Failed to load student count',
      );
    }
  }

  // =========================
  // TEACHERS
  // =========================

  Future<int> getTeacherCount() async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/teachers',
      );

      print('TEACHERS RESPONSE: ${response.data}');

      if (response.data is List) {
        final List<dynamic> teachers = response.data;

        return teachers.length;
      }

      return 0;
    } on DioException catch (e) {
      print('TEACHER COUNT ERROR: ${e.response?.data}');
      print('TEACHER COUNT STATUS: ${e.response?.statusCode}');

      throw Exception(
        'Failed to load teacher count',
      );
    }
  }

  // =========================
  // CLASSES
  // =========================

  Future<int> getClassCount() async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/classes',
      );

      print('CLASSES RESPONSE: ${response.data}');

      if (response.data is List) {
        final List<dynamic> classes = response.data;

        return classes.length;
      }

      return 0;
    } on DioException catch (e) {
      print('CLASS COUNT ERROR: ${e.response?.data}');
      print('CLASS COUNT STATUS: ${e.response?.statusCode}');

      throw Exception(
        'Failed to load class count',
      );
    }
  }

  // =========================
  // ALL DASHBOARD COUNTS
  // =========================

  Future<Map<String, int>> getDashboardCounts() async {
    try {
      final results = await Future.wait([
        getStudentCount(),
        getTeacherCount(),
        getClassCount(),
      ]);

      return {
        'students': results[0],
        'teachers': results[1],
        'classes': results[2],
      };
    } catch (e) {
      print('DASHBOARD COUNT ERROR: $e');

      rethrow;
    }
  }
}