import 'dart:html' as html;
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/report_card_model.dart';

class ReportCardService {
  final ApiClient apiClient;

  ReportCardService(this.apiClient);

  // ============================================================
  // GET REPORT CARD
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

      if (response.data is Map) {
        return ReportCardModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }

      throw Exception('Invalid report card response.');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ============================================================
  // DOWNLOAD REPORT CARD
  // GET /api/v1/report-cards/{studentId}/{examinationId}/download
  // ============================================================

  Future<void> downloadReportCard({
    required int studentId,
    required int examinationId,
  }) async {
    try {
      final response = await apiClient.dio.get<List<int>>(
        '/api/v1/report-cards/$studentId/$examinationId/download',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = response.data;

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Report card file is empty.');
      }

      final fileName =
          'report-card-$studentId-$examinationId.txt';

      final blob = html.Blob(
        <dynamic>[Uint8List.fromList(bytes)],
        'text/plain;charset=utf-8',
      );

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      html.Url.revokeObjectUrl(url);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst('Exception: ', ''),
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
        return 'Invalid report card request.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You do not have permission to view this report card.';
      case 404:
        return 'Report card data not found.';
      case 500:
        return 'Server error. Please try again.';
      default:
        return e.message ?? 'Network error occurred.';
    }
  }
}