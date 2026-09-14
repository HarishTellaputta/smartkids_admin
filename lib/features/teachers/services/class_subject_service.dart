import 'package:dio/dio.dart';
import '../models/class_subject_model.dart';

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

  // Get subjects assigned to a particular class
  Future<List<ClassSubjectModel>> getClassSubjects(int classId) async {
    try {
      final response = await _dio.get(
        '/classes/$classId/subjects',
      );

      final List<dynamic> data = response.data;

      return data
          .map(
            (json) => ClassSubjectModel.fromJson(
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

  // Assign a subject to a class
  Future<void> assignSubjectToClass(
    int classId,
    int subjectId,
  ) async {
    try {
      await _dio.post(
        '/classes/$classId/subjects/$subjectId',
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?.toString() ??
            e.message ??
            'Failed to assign subject to class',
      );
    }
  }

  // Remove a subject from a class
  Future<void> removeSubjectFromClass(
    int classId,
    int subjectId,
  ) async {
    try {
      await _dio.delete(
        '/classes/$classId/subjects/$subjectId',
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