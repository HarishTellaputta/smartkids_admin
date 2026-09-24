import 'package:dio/dio.dart';
import '../models/subject_model.dart';
import '../subject_performance_model.dart';

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
      final response = await _dio.get('/api/v1/subjects');

      final List<dynamic> data = response.data;

      return data
          .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Failed to load subjects',
      );
    }
  }

  // ============================================================
  // GET SUBJECT BY ID
  // GET /subjects/{id}
  // ============================================================

  Future<SubjectModel> getSubjectById(int id) async {
    try {
      final response = await _dio.get('/api/v1/subjects/$id');

      return SubjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Failed to load subject',
      );
    }
  }

  // ============================================================
  // GET SUBJECTS BY SCHOOL
  // GET /subjects/school/{schoolId}
  // ============================================================

  Future<List<SubjectModel>> getSubjectsBySchool(int schoolId) async {
    try {
      final response = await _dio.get('/api/v1/subjects/school/$schoolId');

      final List<dynamic> data = response.data;

      return data
          .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
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

  Future<List<SubjectModel>> getActiveSubjectsBySchool(int schoolId) async {
    try {
      final response = await _dio.get(
        '/api/v1/subjects/school/$schoolId/active',
      );

      final List<dynamic> data = response.data;

      return data
          .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
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

  Future<SubjectModel> createSubject(SubjectModel subject) async {
    try {
      final response = await _dio.post(
        '/api/v1/subjects',
        data: subject.toJson(),
      );

      return SubjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Failed to create subject',
      );
    }
  }

  // ============================================================
  // UPDATE SUBJECT
  // PUT /subjects/{id}
  // ============================================================

  Future<SubjectModel> updateSubject(int id, SubjectModel subject) async {
    try {
      final response = await _dio.put(
        '/api/v1/subjects/$id',
        data: subject.toJson(),
      );

      return SubjectModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Failed to update subject',
      );
    }
  }

  // ============================================================
  // DELETE SUBJECT
  // DELETE /subjects/{id}
  // ============================================================

  Future<void> deleteSubject(int id) async {
    try {
      await _dio.delete('/api/v1/subjects/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Failed to delete subject',
      );
    }
  }

  Future<List<SubjectPerformanceModel>> getSubjectPerformance(
    int subjectId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/subjects/$subjectId/performance',
      );
      final List<dynamic> data = response.data;
      return data
          .map(
            (json) =>
                SubjectPerformanceModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to load subject performance',
      );
    }
  }
}
