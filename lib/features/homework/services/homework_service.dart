import 'package:dio/dio.dart';
import 'package:smartkids_admin/features/homework/models/homework_model.dart';

class HomeworkService {
  final Dio _dio;

  HomeworkService({String baseUrl = 'http://localhost:8080'})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ============================================================
  // GET ALL HOMEWORK
  // ============================================================

  Future<List<HomeworkModel>> getAllHomework() async {
    try {
      final response = await _dio.get('/api/v1/homeworks');

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET HOMEWORK BY ID
  // ============================================================

  Future<HomeworkModel> getHomeworkById(int id) async {
    try {
      final response = await _dio.get('/api/v1/homeworks/$id');

      return HomeworkModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // CREATE HOMEWORK
  // ============================================================

  Future<HomeworkModel> createHomework({
    required int classId,
    int? sectionId,
    required int teacherId,
    String? subject,
    required String title,
    String? description,
    required String dueDate,
    String? status,
    String? attachmentUrl,
    String? priority,
  }) async {
    try {
      final body = {
        'classId': classId,
        'sectionId': sectionId,
        'teacherId': teacherId,
        'subject': subject,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'status': status,
        'attachmentUrl': attachmentUrl,
        'priority': priority,
      };

      final response = await _dio.post('/api/v1/homeworks', data: body);

      return HomeworkModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // UPDATE HOMEWORK
  // ============================================================

  Future<HomeworkModel> updateHomework({
    required int id,
    required int classId,
    int? sectionId,
    required int teacherId,
    String? subject,
    required String title,
    String? description,
    required String dueDate,
    String? status,
    String? attachmentUrl,
    String? priority,
  }) async {
    try {
      final body = {
        'classId': classId,
        'sectionId': sectionId,
        'teacherId': teacherId,
        'subject': subject,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'status': status,
        'attachmentUrl': attachmentUrl,
        'priority': priority,
      };

      final response = await _dio.put('/api/v1/homeworks/$id', data: body);

      return HomeworkModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // DELETE HOMEWORK
  // ============================================================

  Future<void> deleteHomework(int id) async {
    try {
      await _dio.delete('/api/v1/homeworks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY CLASS
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkByClass(int classId) async {
    try {
      final response = await _dio.get('/api/v1/homeworks/class/$classId');

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY SECTION
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkBySection(int sectionId) async {
    try {
      final response = await _dio.get('/api/v1/homeworks/section/$sectionId');

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY CLASS + SECTION
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkByClassAndSection({
    required int classId,
    required int sectionId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/homeworks/class/$classId/section/$sectionId',
      );

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY TEACHER
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkByTeacher(int teacherId) async {
    try {
      final response = await _dio.get('/api/v1/homeworks/teacher/$teacherId');

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY SUBJECT
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkBySubject(String subject) async {
    try {
      final response = await _dio.get(
        '/api/v1/homeworks/subject/${Uri.encodeComponent(subject)}',
      );

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET BY CLASS + SUBJECT
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkByClassAndSubject({
    required int classId,
    required String subject,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/homeworks/class/$classId/subject/${Uri.encodeComponent(subject)}',
      );

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET DATE RANGE
  // ============================================================

  Future<List<HomeworkModel>> getHomeworkByDateRange({
    required int classId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/homeworks/class/$classId/date-range',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET ACTIVE BY CLASS
  // ============================================================

  Future<List<HomeworkModel>> getActiveHomeworkByClass(int classId) async {
    try {
      final response = await _dio.get(
        '/api/v1/homeworks/class/$classId/active',
      );

      return _parseHomeworkList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // PARSE LIST
  // ============================================================

  List<HomeworkModel> _parseHomeworkList(dynamic data) {
    if (data is List) {
      return data
          .map(
            (item) => HomeworkModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        return (data['content'] as List)
            .map(
              (item) => HomeworkModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (data['data'] is List) {
        return (data['data'] as List)
            .map(
              (item) => HomeworkModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      return [HomeworkModel.fromJson(data)];
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleError(DioException e) {
    if (e.response == null) {
      return 'Unable to connect to server.';
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid homework data.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'You do not have permission.';
      case 404:
        return 'Homework not found.';
      case 409:
        return 'Homework already exists.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return e.response?.data?['message']?.toString() ??
            'Something went wrong.';
    }
  }
}
