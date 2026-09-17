
import 'package:dio/dio.dart';
import 'package:smartkids_admin/models/parent_model.dart';

class ParentService {
  late final Dio dio;

  ParentService(String token) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api/v1',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  // ============================================================
  // GET ALL PARENTS
  // GET /parents
  // ============================================================

  Future<List<Parent>> getParents() async {
    try {
      final response = await dio.get('/parents');

      dynamic data = response.data;

      // Supports:
      // [...]
      // {"content":[...]}
      // {"data":[...]}
      // {"parents":[...]}

      if (data is Map<String, dynamic>) {
        data = data['content'] ??
            data['data'] ??
            data['parents'] ??
            [];
      }

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (json) => Parent.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // GET PARENT BY ID
  // GET /parents/{id}
  // ============================================================

  Future<Parent> getParent(int id) async {
    try {
      final response = await dio.get('/parents/$id');

      return Parent.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // CREATE PARENT
  // POST /parents
  // ============================================================

  Future<Parent> createParent({
    required String fatherName,
    required String motherName,
    required String guardianName,
    required String contactPhone,
    required String contactEmail,
    required String relationship,
    required String address,
  }) async {
    try {
      final response = await dio.post(
        '/parents',
        data: {
          'fatherName': fatherName,
          'motherName': motherName,
          'guardianName': guardianName,
          'contactPhone': contactPhone,
          'contactEmail': contactEmail,
          'relationship': relationship,
          'address': address,
        },
      );

      return Parent.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // UPDATE PARENT
  // PUT /parents/{id}
  // ============================================================

  Future<Parent> updateParent({
    required int id,
    required String fatherName,
    required String motherName,
    required String guardianName,
    required String contactPhone,
    required String contactEmail,
    required String relationship,
    required String address,
  }) async {
    try {
      final response = await dio.put(
        '/parents/$id',
        data: {
          'fatherName': fatherName,
          'motherName': motherName,
          'guardianName': guardianName,
          'contactPhone': contactPhone,
          'contactEmail': contactEmail,
          'relationship': relationship,
          'address': address,
        },
      );

      return Parent.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // DELETE PARENT
  // DELETE /parents/{id}
  // ============================================================

  Future<void> deleteParent(int id) async {
    try {
      await dio.delete('/parents/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // LINK STUDENT TO PARENT
  // POST /parents/{parentId}/students/{studentId}
  // ============================================================

  Future<void> linkStudent({
    required int parentId,
    required int studentId,
  }) async {
    try {
      await dio.post(
        '/parents/$parentId/students/$studentId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // UNLINK STUDENT FROM PARENT
  // DELETE /parents/{parentId}/students/{studentId}
  // ============================================================

  Future<void> unlinkStudent({
    required int parentId,
    required int studentId,
  }) async {
    try {
      await dio.delete(
        '/parents/$parentId/students/$studentId',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return Exception('Session expired. Please login again.');
    }

    if (e.response?.statusCode == 403) {
      return Exception(
        'You do not have permission to perform this action.',
      );
    }

    if (e.response?.statusCode == 404) {
      return Exception('Parent not found.');
    }

    if (e.response?.statusCode == 409) {
      return Exception(
        e.response?.data?['message'] ??
            'Parent already exists.',
      );
    }

    if (e.response?.data is Map) {
      final message = e.response?.data['message'];

      if (message != null) {
        return Exception(message.toString());
      }
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'Unable to connect to server.',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Server request timed out.',
      );
    }

    return Exception(
      'Something went wrong. Please try again.',
    );
  }

}