
import 'package:dio/dio.dart';

import '../models/class_subject_model.dart';

class ClassSubjectService {
  final Dio _dio;

  ClassSubjectService(String token)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  // ============================================================
  // GET SUBJECTS ASSIGNED TO CLASS
  //
  // GET /classes/{classId}/subjects
  // ============================================================

  Future<List<ClassSubjectModel>> getClassSubjects(
    int classId,
  ) async {
    try {
      final response = await _dio.get(
        '/classes/$classId/subjects',
      );

      if (response.data is! List) {
        throw Exception(
          'Invalid response received while loading class subjects.',
        );
      }

      final List<dynamic> data = response.data;

      return data
          .map(
            (json) => ClassSubjectModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          defaultMessage: 'Failed to load class subjects',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // ASSIGN SUBJECT TO CLASS
  //
  // POST /classes/{classId}/subjects/{subjectId}
  //
  // Example:
  // POST /classes/1/subjects/5
  // ============================================================

  Future<ClassSubjectModel> assignSubjectToClass(
    int classId,
    int subjectId,
  ) async {
    try {
      final response = await _dio.post(
        '/classes/$classId/subjects/$subjectId',
      );

      // Backend returns ClassSubjectResponse
      if (response.data is Map) {
        return ClassSubjectModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }

      throw Exception(
        'Subject was assigned, but the server returned an invalid response.',
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          defaultMessage: 'Failed to assign subject to class',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // REMOVE SUBJECT FROM CLASS
  //
  // DELETE /classes/{classId}/subjects/{subjectId}
  // ============================================================

  Future<void> removeSubjectFromClass(
    int classId,
    int subjectId,
  ) async {
    try {
      await _dio.delete(
        '/classes/$classId/subjects/$subjectId',
      );
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(
          e,
          defaultMessage: 'Failed to remove subject from class',
        ),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _getErrorMessage(
    DioException error, {
    required String defaultMessage,
  }) {
    final response = error.response;

    if (response != null) {
      final data = response.data;

      // Spring Boot error response:
      //
      // {
      //   "timestamp": "...",
      //   "status": 400,
      //   "error": "...",
      //   "message": "..."
      // }
      if (data is Map) {
        final message = data['message'];

        if (message != null &&
            message.toString().trim().isNotEmpty) {
          return message.toString();
        }

        final errorMessage = data['error'];

        if (errorMessage != null &&
            errorMessage.toString().trim().isNotEmpty) {
          return errorMessage.toString();
        }
      }

      final statusCode = response.statusCode;

      switch (statusCode) {
        case 400:
          return 'Invalid class or subject information.';

        case 401:
          return 'Unauthorized. Please login again.';

        case 403:
          return 'You do not have permission to assign subjects.';

        case 404:
          return 'Class or subject was not found.';

        case 409:
          return 'This subject is already assigned to this class.';

        case 500:
          return 'Server error while assigning subject. Please check the backend logs.';
      }

      return 'Server returned status $statusCode.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check whether Spring Boot is running.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout.';

      case DioExceptionType.connectionError:
        return 'Cannot connect to Spring Boot server.';

      case DioExceptionType.badResponse:
        return defaultMessage;

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      default:
        return error.message ?? defaultMessage;
    }
  }
}

