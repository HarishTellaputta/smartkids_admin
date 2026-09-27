import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/report_card_model.dart';

class ReportCardService {
  final ApiClient apiClient;

  ReportCardService(this.apiClient);

  // ============================================================
  // VIEW REPORT CARD
  // GET /api/v1/report-cards/{studentId}/{examinationId}
  // ============================================================

  Future<ReportCardModel> getReportCard({
    required int studentId,
    required int examinationId,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/report-cards/$studentId/$examinationId',
      );

      print('========================================');
      print('REPORT CARD');
      print('STUDENT ID: $studentId');
      print('EXAMINATION ID: $examinationId');
      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.data}');
      print('========================================');

      if (response.data is! Map) {
        throw Exception('Invalid report card response');
      }

      return ReportCardModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to load report card: $e');
    }
  }

  // ============================================================
  // DOWNLOAD REPORT CARD
  //
  // GET /api/v1/report-cards/{studentId}/{examinationId}/download
  //
  // Backend currently returns TEXT_PLAIN / .txt
  // ============================================================

  Future<List<int>> downloadReportCard({
    required int studentId,
    required int examinationId,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/api/v1/report-cards/$studentId/$examinationId/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      print('========================================');
      print('REPORT CARD DOWNLOAD');
      print('STUDENT ID: $studentId');
      print('EXAMINATION ID: $examinationId');
      print('STATUS: ${response.statusCode}');
      print('BYTES: ${response.data?.length}');
      print('========================================');

      if (response.data is List<int>) {
        return response.data as List<int>;
      }

      if (response.data is List) {
        return List<int>.from(response.data);
      }

      throw Exception('Invalid report card download response');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception('Failed to download report card: $e');
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
          data['message'] ??
          data['error'] ??
          data['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (status) {
      case 400:
        return 'Invalid report card request.';

      case 401:
        return 'Session expired. Please login again.';

      case 403:
        return 'You do not have permission to view this report card.';

      case 404:
        return 'Report card not found.';

      case 500:
        return 'Server error. Please try again.';

      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}