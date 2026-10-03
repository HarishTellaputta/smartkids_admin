import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:smartkids_admin/core/network/api_client.dart';
import '../models/class_model.dart';
import '../models/class_subject_model.dart';

class ClassService {
  final ApiClient apiClient;

  ClassService(this.apiClient);

  // ============================================================
  // GET ALL CLASSES
  // GET /api/v1/classes
  // ============================================================

  Future<List<SchoolClass>> getClasses() async {
    try {
      final response = await apiClient.dio.get('/api/v1/classes');

      return _parseClassList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load classes: $e');
    }
  }

  // ============================================================
  // GET CLASS BY ID
  // GET /api/v1/classes/{id}
  // ============================================================

  Future<SchoolClass> getClassById(int id) async {
    try {
      final response = await apiClient.dio.get('/api/v1/classes/$id');

      return SchoolClass.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load class: $e');
    }
  }

  // ============================================================
  // GET CLASSES BY SCHOOL
  // GET /api/v1/classes/school/{schoolId}
  // ============================================================

  Future<List<SchoolClass>> getClassesBySchool(int schoolId) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/classes/school/$schoolId',
      );

      return _parseClassList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load school classes: $e');
    }
  }

  // ============================================================
  // CREATE CLASS
  // POST /api/v1/classes
  // ============================================================

  Future<SchoolClass> createClass({
    required int schoolId,
    required String name,
    required String code,
    required String grade,
    required int year,
    String? description,
  }) async {
    try {
      final body = {
        'schoolId': schoolId,
        'name': name,
        'code': code,
        'grade': grade,
        'year': year,
        'description': description,
      };

      final response = await apiClient.dio.post('/api/v1/classes', data: body);

      return SchoolClass.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to create class: $e');
    }
  }

  // ============================================================
  // UPDATE CLASS
  // PUT /api/v1/classes/{id}
  // ============================================================

  Future<SchoolClass> updateClass({
    required int id,
    required int schoolId,
    required String name,
    required String code,
    required String grade,
    required int year,
    String? description,
  }) async {
    try {
      final body = {
        'schoolId': schoolId,
        'name': name,
        'code': code,
        'grade': grade,
        'year': year,
        'description': description,
      };

      final response = await apiClient.dio.put(
        '/api/v1/classes/$id',
        data: body,
      );

      return SchoolClass.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update class: $e');
    }
  }

  // ============================================================
  // DELETE CLASS
  // DELETE /api/v1/classes/{id}
  // ============================================================

  Future<void> deleteClass(int id) async {
    try {
      await apiClient.dio.delete('/api/v1/classes/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to delete class: $e');
    }
  }

  // ============================================================
  // CLASS → SUBJECT
  // ============================================================

  // ============================================================
  // ASSIGN SUBJECT TO CLASS
  //
  // POST /classes/{classId}/subjects/{subjectId}
  // ============================================================

  Future<ClassSubjectModel> assignSubjectToClass({
    required int classId,
    required int subjectId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/classes/$classId/subjects/$subjectId',
      );

      return ClassSubjectModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleClassSubjectError(e));
    } catch (e) {
      throw Exception('Failed to assign subject to class: $e');
    }
  }

  // ============================================================
  // GET SUBJECTS ASSIGNED TO CLASS
  //
  // GET /classes/{classId}/subjects
  // ============================================================

  Future<List<ClassSubjectModel>> getSubjectsByClass(int classId) async {
    try {
      final response = await apiClient.dio.get('/classes/$classId/subjects');

      if (response.data is List) {
        return (response.data as List)
            .map(
              (json) =>
                  ClassSubjectModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(_handleClassSubjectError(e));
    } catch (e) {
      throw Exception('Failed to load class subjects: $e');
    }
  }

  // ============================================================
  // REMOVE SUBJECT FROM CLASS
  //
  // DELETE /classes/{classId}/subjects/{subjectId}
  // ============================================================

  Future<void> removeSubjectFromClass({
    required int classId,
    required int subjectId,
  }) async {
    try {
      await apiClient.dio.delete('/classes/$classId/subjects/$subjectId');
    } on DioException catch (e) {
      throw Exception(_handleClassSubjectError(e));
    } catch (e) {
      throw Exception('Failed to remove subject from class: $e');
    }
  }

  // ============================================================
  // PARSE CLASS LIST
  // ============================================================

  List<SchoolClass> _parseClassList(dynamic data) {
    if (data is List) {
      return data
          .map((json) => SchoolClass.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((json) => SchoolClass.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    return [];
  }

  // ============================================================
  // GENERAL ERROR HANDLER
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
        return 'Class not found.';
      }

      if (statusCode == 409) {
        return 'Class already exists.';
      }

      if (statusCode != null && statusCode >= 500) {
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
  // CLASS → SUBJECT ERROR HANDLER
  // ============================================================

  String _handleClassSubjectError(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      if (response.data is Map && response.data['message'] != null) {
        return response.data['message'].toString();
      }

      if (statusCode == 400) {
        return 'Invalid class or subject.';
      }

      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (statusCode == 403) {
        return 'Access denied. You do not have permission.';
      }

      if (statusCode == 404) {
        return 'Class or subject not found.';
      }

      if (statusCode == 409) {
        return 'Subject is already assigned to this class.';
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

  // ============================================================
  // IMPORT CLASSES EXCEL
  // POST /api/v1/classes/import?schoolId={schoolId}
  // ============================================================

  Future<Map<String, dynamic>> importClassesExcel({
    required int schoolId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final response = await apiClient.dio.post(
        '/api/v1/classes/import',
        queryParameters: {'schoolId': schoolId},
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }

      return {
        'totalRows': 0,
        'createdCount': 0,
        'updatedCount': 0,
        'failedCount': 0,
        'errors': <String>[],
        'message': 'Classes imported successfully.',
      };
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to import classes Excel: $e');
    }
  }
}
