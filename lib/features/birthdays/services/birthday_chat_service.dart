import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/birthday_chat_message_model.dart';
import '../models/student_birthday_model.dart';

class BirthdayChatService {
  final ApiClient _apiClient;

  BirthdayChatService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ============================================================
  // GET TODAY'S BIRTHDAY STUDENTS
  // ============================================================

  Future<List<StudentBirthdayModel>> getBirthdayStudents() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/student-birthday-status/chat',
      );

      if (response.data is List) {
        return (response.data as List)
            .map(
              (json) => StudentBirthdayModel.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load birthday students: $e');
    }
  }

  // ============================================================
  // GET CHAT MESSAGES FOR A STUDENT
  // ============================================================

  Future<List<BirthdayChatMessageModel>> getMessages(int studentId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/birthday-chat/$studentId',
      );

      if (response.data is List) {
        return (response.data as List)
            .map(
              (json) => BirthdayChatMessageModel.fromJson(
                Map<String, dynamic>.from(json),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load chat messages: $e');
    }
  }

  // ============================================================
  // SEND MESSAGE
  //
  // replyToMessageId is optional.
  // We use the normal send-message endpoint for replies because
  // the backend's dedicated /reply endpoint is parent-specific.
  // ============================================================

  Future<BirthdayChatMessageModel> sendMessage({
    required int studentId,
    required String message,
    int? replyToMessageId,
  }) async {
    try {
      final Map<String, dynamic> data = {'message': message};

      if (replyToMessageId != null) {
        data['replyToMessageId'] = replyToMessageId;
      }

      final response = await _apiClient.dio.post(
        '/api/v1/birthday-chat/$studentId/messages',
        data: data,
      );

      return BirthdayChatMessageModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // ============================================================
  // EDIT MESSAGE
  // ============================================================

  Future<BirthdayChatMessageModel> editMessage({
    required int messageId,
    required String message,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/v1/birthday-chat/messages/$messageId',
        data: {'message': message},
      );

      return BirthdayChatMessageModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> deleteMessage(int messageId) async {
    try {
      await _apiClient.dio.delete('/api/v1/birthday-chat/messages/$messageId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // ============================================================
  // REPLY TO MESSAGE
  //
  // Not using the backend /reply endpoint here.
  // Instead sendMessage() with replyToMessageId is used.
  // ============================================================

  Future<BirthdayChatMessageModel> replyToMessage({
    required int studentId,
    required int messageId,
    required String message,
  }) async {
    return sendMessage(
      studentId: studentId,
      message: message,
      replyToMessageId: messageId,
    );
  }

  // ============================================================
  // ADD REACTION
  // ============================================================

  Future<void> addReaction({
    required int messageId,
    required String reaction,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/v1/birthday-chat/messages/$messageId/reaction',
        data: {'reaction': reaction},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // ============================================================
  // REMOVE REACTION
  // ============================================================

  Future<void> removeReaction({
    required int messageId,
    required String reaction,
  }) async {
    try {
      await _apiClient.dio.delete(
        '/api/v1/birthday-chat/messages/$messageId/reaction',
        data: {'reaction': reaction},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      String message = 'Request failed';

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['error'] != null) {
          message = data['error'].toString();
        }
      } else if (data != null) {
        message = data.toString();
      }

      switch (statusCode) {
        case 400:
          return Exception('Bad request: $message');

        case 401:
          return Exception('Unauthorized. Please login again.');

        case 403:
          return Exception(
            'Access denied. You do not have permission to perform this action.',
          );

        case 404:
          return Exception('Data not found: $message');

        case 409:
          return Exception('Conflict: $message');

        case 500:
          return Exception('Server error. Please try again later.');

        default:
          return Exception('$message (HTTP $statusCode)');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Server connection timed out. Please check your backend.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'Cannot connect to server. Please make sure Spring Boot is running.',
      );
    }

    return Exception(
      e.message ?? 'Something went wrong while connecting to the server.',
    );
  }
}
