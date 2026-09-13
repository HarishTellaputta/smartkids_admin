import 'package:dio/dio.dart';
import '../models/subject_model.dart';

class ClassSubjectService {
  final Dio _dio;

  ClassSubjectService(String token)
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
  // GET SUBJECTS ASSIGNED TO A CLASS
  // GET /api/v1/classes/{classId}/subjects
  // ============================================================

  Future<List<SubjectModel>> getClassSubjects(
    int classId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/classes/$classId/subjects',
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
            'Failed to load class subjects',
      );
    }
  }

  // ============================================================
  // ASSIGN SUBJECT TO CLASS
  // POST /api/v1/classes/{classId}/subjects/{subjectId}
  // ============================================================

  Future<void> assignSubjectToClass(
    int classId,
    int subjectId,
  ) async {
    try {
      await _dio.post(
        '/api/v1/classes/$classId/subjects/$subjectId',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to assign subject to class',
      );
    }
  }

  // ============================================================
  // REMOVE SUBJECT FROM CLASS
  // DELETE /api/v1/classes/{classId}/subjects/{subjectId}
  // ============================================================

  Future<void> removeSubjectFromClass(
    int classId,
    int subjectId,
  ) async {
    try {
      await _dio.delete(
        '/api/v1/classes/$classId/subjects/$subjectId',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to remove subject from class',
      );
    }
  }
}