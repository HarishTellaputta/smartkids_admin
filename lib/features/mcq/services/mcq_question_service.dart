import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/mcq_question_model.dart';

class McqQuestionService {
  final Dio _dio;

  McqQuestionService(String token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
          },
        ),
      );

  // ============================================================
  // GET QUESTIONS
  // ============================================================

  Future<List<McqQuestionModel>> getQuestions({
    String? date,
    int? classId,
    String? subject,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (date != null && date.trim().isNotEmpty) {
        queryParameters['date'] = date.trim();
      }

      if (classId != null) {
        queryParameters['classId'] = classId;
      }

      if (subject != null && subject.trim().isNotEmpty) {
        queryParameters['subject'] = subject.trim();
      }

      final response = await _dio.get(
        '/api/v1/mcq-questions',
        queryParameters: queryParameters,
      );

      final data = response.data;

      // Backend returns List
      if (data is List) {
        return data
            .map(
              (json) =>
                  McqQuestionModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      // In case backend returns { content: [...] }
      if (data is Map<String, dynamic>) {
        if (data['content'] is List) {
          return (data['content'] as List)
              .map(
                (json) =>
                    McqQuestionModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }

        // In case backend returns { data: [...] }
        if (data['data'] is List) {
          return (data['data'] as List)
              .map(
                (json) =>
                    McqQuestionModel.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load MCQ questions: $e');
    }
  }

  // ============================================================
  // GET QUESTION BY ID
  // ============================================================

  Future<McqQuestionModel> getQuestionById(int id) async {
    try {
      final response = await _dio.get('/api/v1/mcq-questions/$id');

      return McqQuestionModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load MCQ question: $e');
    }
  }

  // ============================================================
  // CREATE QUESTION
  // ============================================================

  Future<McqQuestionModel> createQuestion(McqQuestionModel question) async {
    try {
      final response = await _dio.post(
        '/api/v1/mcq-questions',
        data: question.toJson(),
      );

      return McqQuestionModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to create MCQ question: $e');
    }
  }

  // ============================================================
  // UPDATE QUESTION
  // ============================================================

  Future<McqQuestionModel> updateQuestion(
    int id,
    McqQuestionModel question,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/mcq-questions/$id',
        data: question.toJson(),
      );

      return McqQuestionModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to update MCQ question: $e');
    }
  }

  // ============================================================
  // DELETE QUESTION
  // ============================================================

  Future<void> deleteQuestion(int id) async {
    try {
      await _dio.delete('/api/v1/mcq-questions/$id');
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to delete MCQ question: $e');
    }
  }

  // ============================================================
  // IMPORT QUESTIONS FROM EXCEL
  // ============================================================
  //
  // IMPORTANT:
  // Flutter Web/Chrome lo FilePicker path reliable kaadu.
  // Kabatti bytes + filename ni direct ga MultipartFile ki pass chestham.
  //
  // Backend endpoint:
  // POST /api/v1/mcq-questions/import-excel
  //
  // Form field:
  // file
  //
  // Returns:
  // {
  //   "message": "MCQ Excel imported successfully",
  //   "importedQuestions": 10
  // }
  //
  // ============================================================

  Future<int> importExcel({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      debugPrint('SERVICE: Preparing Excel upload...');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      debugPrint('SERVICE: FormData created');
      debugPrint(
        'SERVICE: POST http://localhost:8080/api/v1/mcq-questions/import-excel',
      );

      final response = await _dio.post(
        '/api/v1/mcq-questions/import-excel',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      debugPrint('SERVICE: Response status = ${response.statusCode}');
      debugPrint('SERVICE: Response data = ${response.data}');

      final data = response.data;

      if (data is Map<String, dynamic>) {
        final imported = data['importedQuestions'];

        if (imported is int) {
          return imported;
        }

        if (imported != null) {
          return int.tryParse(imported.toString()) ?? 0;
        }
      }

      return 0;
    } on DioException catch (e) {
      debugPrint('SERVICE DIO ERROR');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');

      throw Exception(_handleDioError(e));
    } catch (e) {
      debugPrint('SERVICE ERROR: $e');
      throw Exception('Failed to import MCQ Excel: $e');
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================
  String _handleDioError(DioException error) {
    final response = error.response;

    // ============================================================
    // SERVER RESPONSE ERROR
    // ============================================================

    if (response != null) {
      final statusCode = response.statusCode;

      if (statusCode == 400) {
        return _extractMessage(
          response,
          'Bad request. Please check the entered data.',
        );
      }

      if (statusCode == 401) {
        return 'Unauthorized. Please login again.';
      }

      if (statusCode == 403) {
        return 'Access denied. You do not have permission.';
      }

      if (statusCode == 404) {
        return 'MCQ question or API endpoint not found.';
      }

      if (statusCode == 409) {
        return _extractMessage(response, 'MCQ question already exists.');
      }

      if (statusCode == 413) {
        return 'Excel file is too large.';
      }

      if (statusCode == 415) {
        return 'Unsupported file format. Please upload .xlsx or .xls.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      return _extractMessage(response, 'Server returned an error.');
    }

    // ============================================================
    // CONNECTION / REQUEST ERRORS
    // ============================================================

    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check the server.';
    }

    if (error.type == DioExceptionType.sendTimeout) {
      return 'Request timeout. Please try again.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Make sure Spring Boot is running.';
    }

    if (error.type == DioExceptionType.badCertificate) {
      return 'Server certificate error.';
    }

    if (error.type == DioExceptionType.cancel) {
      return 'Request cancelled.';
    }

    if (error.type == DioExceptionType.badResponse) {
      return 'Server returned an error.';
    }

    // ============================================================
    // UNKNOWN ERROR
    // ============================================================

    return error.message ?? 'Something went wrong.';
  }
  // ============================================================
  // EXTRACT SERVER MESSAGE
  // ============================================================

  String _extractMessage(Response response, String fallback) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['detail'] != null) {
        return data['detail'].toString();
      }

      if (data['errors'] != null) {
        return data['errors'].toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return fallback;
  }
}
