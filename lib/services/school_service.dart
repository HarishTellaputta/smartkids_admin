import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class SchoolService {
  final ApiClient apiClient;

  SchoolService(this.apiClient);

  Future<Map<String, dynamic>> importSchoolsExcel({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      print('========================================');
      print('SCHOOL EXCEL IMPORT STARTED');
      print('FILE NAME: $fileName');
      print('FILE SIZE: ${fileBytes.length} bytes');
      print('========================================');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      print('Calling: POST /api/v1/schools/import');

      final response = await apiClient.dio.post(
        '/api/v1/schools/import',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      print('========================================');
      print('SCHOOL IMPORT RESPONSE');
      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');
      print('========================================');

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return {
        'totalRows': 0,
        'createdCount': 0,
        'updatedCount': 0,
        'failedCount': 0,
        'errors': <String>[],
        'message': 'School import completed.',
      };
    } on DioException catch (e) {
      print('========================================');
      print('SCHOOL IMPORT DIO ERROR');
      print('STATUS: ${e.response?.statusCode}');
      print('URL: ${e.requestOptions.uri}');
      print('RESPONSE: ${e.response?.data}');
      print('MESSAGE: ${e.message}');
      print('========================================');

      final data = e.response?.data;

      if (data is Map) {
        final message =
            data['message'] ?? data['error'] ?? 'School Excel import failed.';

        throw Exception(message.toString());
      }

      throw Exception(e.message ?? 'School Excel import failed.');
    } catch (e) {
      print('========================================');
      print('SCHOOL IMPORT ERROR: $e');
      print('========================================');

      throw Exception('Failed to import schools Excel: $e');
    }
  }
}
