import 'package:dio/dio.dart';
import 'package:smartkids_admin/features/teachers/models/available_teacher_user_model.dart';

import '../models/teacher_model.dart';

class TeacherService {
  final Dio _dio;

  TeacherService(String token)
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
  // GET ALL TEACHERS
  // GET /api/v1/teachers
  // ============================================================

  Future<List<Teacher>> getTeachers() async {
    try {
      final response = await _dio.get('/api/v1/teachers');

      final data = response.data;

      if (data is List) {
        return data
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      // In case backend returns:
      // {
      //   "content": [...]
      // }
      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load teachers: $e');
    }
  }

  // ============================================================
  // GET TEACHER BY ID
  // GET /api/v1/teachers/{id}
  // ============================================================

  Future<Teacher> getTeacherById(int id) async {
    try {
      final response = await _dio.get('/api/v1/teachers/$id');

      return Teacher.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load teacher: $e');
    }
  }

  // ============================================================
  // GET TEACHERS BY SCHOOL
  // GET /api/v1/teachers/school/{schoolId}
  // ============================================================

  Future<List<Teacher>> getTeachersBySchool(int schoolId) async {
    try {
      final response = await _dio.get('/api/v1/teachers/school/$schoolId');

      final data = response.data;

      if (data is List) {
        return data
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load school teachers: $e');
    }
  }

  // ============================================================
  // GET TEACHERS BY STATUS
  // GET /api/v1/teachers/status/{status}
  // ============================================================

  Future<List<Teacher>> getTeachersByStatus(String status) async {
    try {
      final response = await _dio.get('/api/v1/teachers/status/$status');

      final data = response.data;

      if (data is List) {
        return data
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      if (data is Map<String, dynamic> && data['content'] is List) {
        return (data['content'] as List)
            .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load teachers by status: $e');
    }
  }

  // ============================================================
  // CREATE TEACHER
  // POST /api/v1/teachers
  // ============================================================
  Future<Teacher> createTeacher({
    required int schoolId,
    required int userId,
    required String phone,
    String? dateOfBirth,
    String? gender,
    String? joiningDate,
    String? qualification,
    String? designation,
    String? address,
    String? status,
  }) async {
    try {
      final body = {
        'schoolId': schoolId,
        'userId': userId,
        'phone': phone.trim(),

        'dateOfBirth': dateOfBirth?.trim().isEmpty == true
            ? null
            : dateOfBirth?.trim(),

        'gender': gender,

        'joiningDate': joiningDate?.trim().isEmpty == true
            ? null
            : joiningDate?.trim(),

        'qualification': qualification?.trim().isEmpty == true
            ? null
            : qualification?.trim(),

        'designation': designation?.trim().isEmpty == true
            ? null
            : designation?.trim(),

        'address': address?.trim().isEmpty == true ? null : address?.trim(),

        'status': status,
      };

      final response = await _dio.post('/api/v1/teachers', data: body);

      return Teacher.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to create teacher: $e');
    }
  } // ============================================================
  // UPDATE TEACHER
  // PUT /api/v1/teachers/{id}
  // ============================================================

  Future<Teacher> updateTeacher({
    required int id,
    required int schoolId,
    required String employeeId,
    required String name,
    required String email,
    required String phone,
    required String dateOfBirth,
    required String gender,
    required String joiningDate,
    required String qualification,
    required String designation,
    required String address,
    required String status,
    required int userId,
  }) async {
    try {
      final body = {
        'schoolId': schoolId,
        'employeeId': employeeId,
        'name': name,
        'email': email,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'joiningDate': joiningDate,
        'qualification': qualification,
        'designation': designation,
        'address': address,
        'status': status,
        'userId': userId,
      };

      final response = await _dio.put('/api/v1/teachers/$id', data: body);

      return Teacher.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  // ============================================================
  // DELETE TEACHER
  // DELETE /api/v1/teachers/{id}
  // ============================================================

  Future<void> deleteTeacher(int id) async {
    try {
      await _dio.delete('/api/v1/teachers/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  // ============================================================
  // ERROR HANDLER
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
        return 'Teacher not found.';
      }

      if (statusCode == 409) {
        return 'Teacher already exists.';
      }

      if (statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }

      if (response.data is Map && response.data['message'] != null) {
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

  // ============================================================
  // GET AVAILABLE TEACHER USERS
  // GET /api/v1/teachers/available-users
  // ============================================================

  Future<List<AvailableTeacherUser>> getAvailableTeacherUsers() async {
    try {
      final response = await _dio.get('/api/v1/teachers/available-users');

      final data = response.data;

      if (data is List) {
        return data
            .map(
              (json) => AvailableTeacherUser.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load available teacher users: $e');
    }
  }
}
