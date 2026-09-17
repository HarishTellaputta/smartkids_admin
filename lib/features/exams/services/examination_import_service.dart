
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/examination_import_response_model.dart';

class ExaminationImportService {
  final Dio _dio;

  ExaminationImportService(String token)
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:8080',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );

  // ============================================================
  // IMPORT EXAMINATIONS FROM EXCEL
  // POST /api/v1/examinations/import
  // ============================================================

  Future<ExaminationImportResponseModel> importExaminationsExcel({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/v1/examinations/import',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return ExaminationImportResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception(
        'Failed to import examinations Excel: $e',
      );
    }
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
        return 'Invalid Excel file or examination data.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to import examinations.';
      case 404:
        return 'Import endpoint not found.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}

