
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/excel_import_response_model.dart';

class ExaminationBulkImportService {
  final Dio _dio;

  ExaminationBulkImportService(String token)
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

  Future<ExcelImportResponseModel> importResults({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      endpoint: '/api/v1/examinations/results/import',
      bytes: bytes,
      fileName: fileName,
      type: 'exam results',
    );
  }

  Future<ExcelImportResponseModel> importSchedules({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      endpoint: '/api/v1/examinations/schedules/import',
      bytes: bytes,
      fileName: fileName,
      type: 'exam schedules',
    );
  }

  Future<ExcelImportResponseModel> importGradeRules({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      endpoint: '/api/v1/examinations/grade-rules/import',
      bytes: bytes,
      fileName: fileName,
      type: 'grade rules',
    );
  }

  Future<ExcelImportResponseModel> importAcademicYears({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      endpoint: '/api/v1/academic-years/import',
      bytes: bytes,
      fileName: fileName,
      type: 'academic years',
    );
  }

  Future<ExcelImportResponseModel> _upload({
    required String endpoint,
    required Uint8List bytes,
    required String fileName,
    required String type,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('IMPORTING $type');
      debugPrint('ENDPOINT: $endpoint');
      debugPrint('FILE: $fileName');
      debugPrint('BYTES: ${bytes.length}');
      debugPrint('========================================');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint(
        'IMPORT RESPONSE STATUS: ${response.statusCode}',
      );

      debugPrint(
        'IMPORT RESPONSE DATA: ${response.data}',
      );

      return ExcelImportResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e, type));
    } catch (e) {
      throw Exception(
        'Failed to import $type Excel: $e',
      );
    }
  }

  String _handleError(
    DioException e,
    String type,
  ) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message =
          data['message'] ??
          data['error'] ??
          data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (status) {
      case 400:
        return 'Invalid $type Excel file or data.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to import $type.';
      case 404:
        return 'Import endpoint not found.';
      case 500:
        return 'Server error while importing $type.';
      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}

