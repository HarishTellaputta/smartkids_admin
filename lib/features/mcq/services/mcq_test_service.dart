import 'package:dio/dio.dart';

import '../models/mcq_test_model.dart';

class McqTestService {
  final Dio _dio;

  McqTestService(String token)
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
  // CREATE MCQ TEST
  // POST /api/v1/mcq-tests
  // SCHOOL_ADMIN ONLY
  // ============================================================
  Future<McqTestModel> createTest({
    required int classId,
    int? sectionId,
    required String subject,
    required String date,
    required String startTime,
    required int duration,
    required int numberOfQuestions,
  }) async {
    try {
      // ------------------------------------------------------------
      // Convert UI date to backend LocalDate format
      //
      // UI may send:
      // 14-09-2026
      //
      // Backend expects:
      // 2026-09-14
      // ------------------------------------------------------------

      String apiDate = date.trim();

      final dateParts = apiDate.split('-');

      if (dateParts.length == 3 && dateParts[0].length == 2) {
        // dd-MM-yyyy -> yyyy-MM-dd
        apiDate =
            '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
      }

      // ------------------------------------------------------------
      // Convert time to backend LocalTime format
      //
      // Backend expects:
      // HH:mm:ss
      //
      // Examples:
      // 10:30     -> 10:30:00
      // 10:30:00  -> 10:30:00
      // ------------------------------------------------------------

      String apiStartTime = startTime.trim();

      final timeParts = apiStartTime.split(':');

      if (timeParts.length == 2) {
        apiStartTime =
            '${timeParts[0].padLeft(2, '0')}:'
            '${timeParts[1].padLeft(2, '0')}:00';
      } else if (timeParts.length == 3) {
        apiStartTime =
            '${timeParts[0].padLeft(2, '0')}:'
            '${timeParts[1].padLeft(2, '0')}:'
            '${timeParts[2].padLeft(2, '0')}';
      }

      final body = {
        'classId': classId,
        'sectionId': sectionId,
        'subject': subject.trim(),
        'date': apiDate,
        'startTime': apiStartTime,
        'duration': duration,
        'numberOfQuestions': numberOfQuestions,
      };

      print('========================================');
      print('CREATE MCQ TEST REQUEST');
      print('========================================');
      print('classId          : $classId');
      print('sectionId        : $sectionId');
      print('subject          : ${subject.trim()}');
      print('UI date          : $date');
      print('API date         : $apiDate');
      print('UI start time    : $startTime');
      print('API start time   : $apiStartTime');
      print('duration         : $duration');
      print('numberQuestions  : $numberOfQuestions');
      print('REQUEST BODY     : $body');
      print('========================================');

      final response = await _dio.post('/api/v1/mcq-tests', data: body);

      print('CREATE TEST STATUS: ${response.statusCode}');
      print('CREATE TEST RESPONSE: ${response.data}');

      return McqTestModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      print('========================================');
      print('CREATE MCQ TEST DIO ERROR');
      print('STATUS: ${e.response?.statusCode}');
      print('RESPONSE: ${e.response?.data}');
      print('MESSAGE: ${e.message}');
      print('========================================');

      throw Exception(_handleDioError(e));
    } catch (e) {
      print('CREATE MCQ TEST ERROR: $e');
      throw Exception('Failed to create MCQ test: $e');
    }
  }
  // ============================================================
  // GET ALL MCQ TESTS
  // GET /api/v1/mcq-tests
  // ============================================================

  Future<List<McqTestModel>> getTests() async {
    try {
      final response = await _dio.get('/api/v1/mcq-tests');

      return _parseTestList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load MCQ tests: $e');
    }
  }

  // ============================================================
  // GET MCQ TESTS BY DATE
  // GET /api/v1/mcq-tests?date=2026-09-13
  // ============================================================

  Future<List<McqTestModel>> getTestsByDate(String date) async {
    try {
      final response = await _dio.get(
        '/api/v1/mcq-tests',
        queryParameters: {'date': date},
      );

      return _parseTestList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load MCQ tests by date: $e');
    }
  }

  // ============================================================
  // START TEST
  // POST /api/v1/mcq-tests/{testId}/start
  //
  // STUDENT ONLY
  // ============================================================

  Future<McqAttemptModel> startTest({
    required int testId,
    required int studentId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/mcq-tests/$testId/start',
        queryParameters: {'studentId': studentId},
      );

      return McqAttemptModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to start MCQ test: $e');
    }
  }

  // ============================================================
  // ANSWER QUESTION
  // PUT /api/v1/mcq-tests/attempts/{attemptId}/answers
  //
  // STUDENT ONLY
  // ============================================================

  Future<McqAttemptModel> answerQuestion({
    required int attemptId,
    required int studentId,
    required int questionId,
    required String answer,
  }) async {
    try {
      final body = {'questionId': questionId, 'answer': answer.toUpperCase()};

      final response = await _dio.put(
        '/api/v1/mcq-tests/attempts/$attemptId/answers',
        queryParameters: {'studentId': studentId},
        data: body,
      );

      return McqAttemptModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to save answer: $e');
    }
  }

  // ============================================================
  // SUBMIT TEST
  // POST /api/v1/mcq-tests/attempts/{attemptId}/submit
  //
  // STUDENT ONLY
  // ============================================================

  Future<McqAttemptModel> submitTest({
    required int attemptId,
    required int studentId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/mcq-tests/attempts/$attemptId/submit',
        queryParameters: {'studentId': studentId},
      );

      return McqAttemptModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to submit MCQ test: $e');
    }
  }

  // ============================================================
  // STUDENT HISTORY
  // GET /api/v1/mcq-tests/history/{studentId}
  // ============================================================

  Future<List<McqAttemptModel>> getStudentHistory(int studentId) async {
    try {
      final response = await _dio.get('/api/v1/mcq-tests/history/$studentId');

      return _parseAttemptList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load student test history: $e');
    }
  }

  // ============================================================
  // CLASS PERFORMANCE
  // GET /api/v1/mcq-tests/performance/class/{classId}
  // ============================================================

  Future<List<McqAttemptModel>> getClassPerformance(int classId) async {
    try {
      final response = await _dio.get(
        '/api/v1/mcq-tests/performance/class/$classId',
      );

      return _parseAttemptList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load class performance: $e');
    }
  }

  // ============================================================
  // OVERALL PERFORMANCE
  // GET /api/v1/mcq-tests/performance/overall
  // SCHOOL_ADMIN ONLY
  // ============================================================

  Future<List<McqAttemptModel>> getOverallPerformance() async {
    try {
      final response = await _dio.get('/api/v1/mcq-tests/performance/overall');

      return _parseAttemptList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Failed to load overall performance: $e');
    }
  }

  // ============================================================
  // PARSE TEST LIST
  // ============================================================

  List<McqTestModel> _parseTestList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((json) => McqTestModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        return (data['content'] as List)
            .whereType<Map>()
            .map(
              (json) => McqTestModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      if (data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map(
              (json) => McqTestModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // PARSE ATTEMPT LIST
  // ============================================================

  List<McqAttemptModel> _parseAttemptList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (json) => McqAttemptModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        return (data['content'] as List)
            .whereType<Map>()
            .map(
              (json) =>
                  McqAttemptModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      if (data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map>()
            .map(
              (json) =>
                  McqAttemptModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // DIO ERROR HANDLER
  // ============================================================

  String _handleDioError(DioException error) {
    final response = error.response;

    if (response != null) {
      final statusCode = response.statusCode;

      if (statusCode == 400) {
        return _extractServerMessage(
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
        return 'MCQ test not found.';
      }

      if (statusCode == 409) {
        return _extractServerMessage(
          response,
          'MCQ test already exists for this class, section, subject and date.',
        );
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Server error. Please try again later.';
      }

      return _extractServerMessage(response, 'Server returned an error.');
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

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      default:
        return error.message ?? 'Something went wrong.';
    }
  }

  // ============================================================
  // EXTRACT BACKEND ERROR MESSAGE
  // ============================================================

  String _extractServerMessage(Response response, String fallback) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return fallback;
  }
}

// ============================================================
// MCQ ATTEMPT MODEL
// ============================================================


class McqAttemptModel {
  final int? attemptId;
  final int? testId;

  // Student details
  final int? studentId;
  final String? studentName;
  final String? admissionNo;

  final String status;
  final String? startedAt;
  final String? expiresAt;
  final String? submittedAt;

  final int? score;
  final int? totalQuestions;
  final int? correctAnswers;
  final int? wrongAnswers;
  final double? percentage;

  final McqTestModel? test;

  McqAttemptModel({
    this.attemptId,
    this.testId,
    this.studentId,
    this.studentName,
    this.admissionNo,
    required this.status,
    this.startedAt,
    this.expiresAt,
    this.submittedAt,
    this.score,
    this.totalQuestions,
    this.correctAnswers,
    this.wrongAnswers,
    this.percentage,
    this.test,
  });

  factory McqAttemptModel.fromJson(Map<String, dynamic> json) {
    return McqAttemptModel(
      attemptId: _parseInt(json['attemptId']),
      testId: _parseInt(json['testId']),

      // Student details from backend
      studentId: _parseInt(json['studentId']),
      studentName: json['studentName']?.toString(),
      admissionNo: json['admissionNo']?.toString(),

      status: json['status']?.toString() ?? '',

      startedAt: json['startedAt']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      submittedAt: json['submittedAt']?.toString(),

      score: _parseInt(json['score']),
      totalQuestions: _parseInt(json['totalQuestions']),
      correctAnswers: _parseInt(json['correctAnswers']),
      wrongAnswers: _parseInt(json['wrongAnswers']),

      percentage: _parseDouble(json['percentage']),

      test: json['test'] is Map
          ? McqTestModel.fromJson(
              Map<String, dynamic>.from(json['test']),
            )
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
