import 'package:dio/dio.dart';

import 'package:smartkids_admin/core/network/api_client.dart';
import '../models/class_subject_model.dart';

class ClassSubjectService {
  final ApiClient apiClient;

  ClassSubjectService(this.apiClient);

  // ============================================================
  // GET SUBJECTS ASSIGNED TO CLASS
  //
  // GET /classes/{classId}/subjects
  // ============================================================

  Future<List<ClassSubjectModel>> getClassSubjects(
    int classId,
  ) async {
    try {
      final response = await apiClient.dio.get(
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
  // ============================================================

  Future<ClassSubjectModel> assignSubjectToClass(
    int classId,
    int subjectId,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '/classes/$classId/subjects/$subjectId',
      );

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
      await apiClient.dio.delete(
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