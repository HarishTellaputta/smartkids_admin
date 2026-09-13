import 'package:dio/dio.dart';
import '../models/subject_model.dart';
class SubjectService {
  final Dio _dio;

  SubjectService(String token)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080',
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

  // ============================================================
  // GET ALL SUBJECTS
  // GET /subjects
  // ============================================================

  Future<List<SubjectModel>> getAllSubjects() async {
    try {
      final response = await _dio.get('/subjects');

      final List<dynamic> data = response.data;

      return data
          .map(
            (json) => SubjectModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load subjects',
      );
    }
  }

  // ============================================================
  // GET SUBJECT BY ID
  // GET /subjects/{id}
  // ============================================================

  Future<SubjectModel> getSubjectById(int id) async {
    try {
      final response = await _dio.get(
        '/subjects/$id',
      );

      return SubjectModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load subject',
      );
    }
  }

  // ============================================================
  // GET SUBJECTS BY SCHOOL
  // GET /subjects/school/{schoolId}
  // ============================================================

  Future<List<SubjectModel>> getSubjectsBySchool(
    int schoolId,
  ) async {
    try {
      final response = await _dio.get(
        '/subjects/school/$schoolId',
      );

      final List<dynamic> data = response.data;

      return data
          .map(
            (json) => SubjectModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load school subjects',
      );
    }
  }

  // ============================================================
  // GET ACTIVE SUBJECTS BY SCHOOL
  // GET /subjects/school/{schoolId}/active
  // ============================================================

  Future<List<SubjectModel>> getActiveSubjectsBySchool(
    int schoolId,
  ) async {
    try {
      final response = await _dio.get(
        '/subjects/school/$schoolId/active',
      );

      final List<dynamic> data = response.data;

      return data
          .map(
            (json) => SubjectModel.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load active subjects',
      );
    }
  }

  // ============================================================
  // CREATE SUBJECT
  // POST /subjects
  // ============================================================

  Future<SubjectModel> createSubject(
    SubjectModel subject,
  ) async {
    try {
      final response = await _dio.post(
        '/subjects',
        data: subject.toJson(),
      );

      return SubjectModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to create subject',
      );
    }
  }

  // ============================================================
  // UPDATE SUBJECT
  // PUT /subjects/{id}
  // ============================================================

  Future<SubjectModel> updateSubject(
    int id,
    SubjectModel subject,
  ) async {
    try {
      final response = await _dio.put(
        '/subjects/$id',
        data: subject.toJson(),
      );

      return SubjectModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to update subject',
      );
    }
  }

  // ============================================================
  // DELETE SUBJECT
  // DELETE /subjects/{id}
  // ============================================================

  Future<void> deleteSubject(int id) async {
    try {
      await _dio.delete(
        '/subjects/$id',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to delete subject',
      );
    }
  }
}