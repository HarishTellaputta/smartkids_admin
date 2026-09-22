import 'package:dio/dio.dart';
import '../models/notice_model.dart';

class NoticeService {
  final Dio _dio;

  NoticeService(String token)
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
  // GET ALL ADMIN NOTICES
  // GET /api/v1/notifications/admin
  // ============================================================

  Future<List<NoticeModel>> getNotices() async {
    try {
      final response = await _dio.get('/api/v1/notifications/admin');

      print('========================================');
      print('GET ADMIN NOTICES');
      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');
      print('========================================');

      return _parseNoticeList(response.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load notices: $e');
    }
  }

  // ============================================================
  // CREATE NOTICE
  // POST /api/v1/notifications/admin
  // ============================================================

  Future<NoticeModel> createNotice({
    required String title,
    required String message,
    required String category,
    required String audience,
    required String status,
  }) async {
    try {
      final body = {
        'type': 'SCHOOL_NOTICE',
        'title': title.trim(),
        'message': message.trim(),
        'category': category,
        'audience': audience,
        'status': status,
      };

      print('========================================');
      print('CREATE NOTICE');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.post(
        '/api/v1/notifications/admin',
        data: body,
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return NoticeModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to create notice: $e');
    }
  }

  // ============================================================
  // UPDATE NOTICE
  // PUT /api/v1/notifications/admin/{id}
  // ============================================================

  Future<NoticeModel> updateNotice({
    required int id,
    required String title,
    required String message,
    required String category,
    required String audience,
    required String status,
  }) async {
    try {
      final body = {
        'type': 'SCHOOL_NOTICE',
        'title': title.trim(),
        'message': message.trim(),
        'category': category,
        'audience': audience,
        'status': status,
      };

      print('========================================');
      print('UPDATE NOTICE ID: $id');
      print('REQUEST: $body');
      print('========================================');

      final response = await _dio.put(
        '/api/v1/notifications/admin/$id',
        data: body,
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return NoticeModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to update notice: $e');
    }
  }

  // ============================================================
  // DELETE NOTICE
  // DELETE /api/v1/notifications/admin/{id}
  // ============================================================

  Future<void> deleteNotice(int id) async {
    try {
      print('========================================');
      print('DELETE NOTICE ID: $id');
      print('========================================');

      final response = await _dio.delete(
        '/api/v1/notifications/admin/$id',
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to delete notice: $e');
    }
  }

  // ============================================================
  // PUBLISH NOTICE
  // PATCH /api/v1/notifications/admin/{id}/publish
  // ============================================================

  Future<NoticeModel> publishNotice(int id) async {
    try {
      print('========================================');
      print('PUBLISH NOTICE ID: $id');
      print('========================================');

      final response = await _dio.patch(
        '/api/v1/notifications/admin/$id/publish',
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');

      return NoticeModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to publish notice: $e');
    }
  }

  // ============================================================
  // PARSER
  // ============================================================

  List<NoticeModel> _parseNoticeList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) =>
                NoticeModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        return content
            .whereType<Map>()
            .map(
              (item) =>
                  NoticeModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _handleError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message =
          data['message'] ?? data['error'] ?? data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (status) {
      case 400:
        return 'Invalid notice data.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Notice not found.';
      case 409:
        return 'This notice already exists.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}