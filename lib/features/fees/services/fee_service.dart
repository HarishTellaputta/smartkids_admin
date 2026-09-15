import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fee_model.dart';
import '../models/fee_dashboard_summary_model.dart';

class FeeService {
  final Dio _dio;

  FeeService({String baseUrl = 'http://localhost:8080'})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('JWT token not found. Please login again.');
    }

    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // PENDING FEES
  // ============================================================

  Future<List<StudentFeeModel>> getPendingFees() async {
    try {
      final response = await _dio.get(
        '/api/v1/fees/pending',
        options: Options(
          headers: await _headers(),
        ),
      );

      return _parseStudentFees(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // STUDENT FEES
  // ============================================================

  Future<List<StudentFeeModel>> getStudentFees(
    int studentId, {
    bool pending = false,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/fees/students/$studentId',
        queryParameters: {
          'pending': pending,
        },
        options: Options(
          headers: await _headers(),
        ),
      );

      return _parseStudentFees(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // PAYMENTS
  // ============================================================

  Future<List<FeePaymentModel>> getPayments({
    int? studentId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/fees/payments',
        queryParameters: studentId == null
            ? null
            : {
                'studentId': studentId,
              },
        options: Options(
          headers: await _headers(),
        ),
      );

      return _parsePayments(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // RECORD PAYMENT
  // ============================================================

  Future<FeePaymentModel> recordPayment({
    required int studentFeeId,
    required double amount,
    required String paymentMethod,
    String? remarks,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/fees/payments',
        data: {
          'studentFeeId': studentFeeId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'remarks': remarks ?? '',
        },
        options: Options(
          headers: await _headers(),
        ),
      );

      return FeePaymentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // FEE STRUCTURES
  // ============================================================

  Future<List<dynamic>> getFeeStructures({
    int? classId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/fees/structures',
        queryParameters: classId == null
            ? null
            : {
                'classId': classId,
              },
        options: Options(
          headers: await _headers(),
        ),
      );

      if (response.data is List) {
        return List<dynamic>.from(response.data);
      }

      return [];
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // FEE DASHBOARD SUMMARY
  // GET /api/v1/fees/dashboard-summary
  // ============================================================

  Future<FeeDashboardSummaryModel> getDashboardSummary() async {
    try {
      final response = await _dio.get(
        '/api/v1/fees/dashboard-summary',
        options: Options(
          headers: await _headers(),
        ),
      );

      return FeeDashboardSummaryModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  // ============================================================
  // PARSE STUDENT FEES
  // ============================================================

  List<StudentFeeModel> _parseStudentFees(dynamic data) {
    if (data is List) {
      return data
          .map(
            (item) => StudentFeeModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    if (data is Map && data['content'] is List) {
      return (data['content'] as List)
          .map(
            (item) => StudentFeeModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    return [];
  }

  // ============================================================
  // PARSE PAYMENTS
  // ============================================================

  List<FeePaymentModel> _parsePayments(dynamic data) {
    if (data is List) {
      return data
          .map(
            (item) => FeePaymentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    if (data is Map && data['content'] is List) {
      return (data['content'] as List)
          .map(
            (item) => FeePaymentModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    return [];
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _getErrorMessage(DioException e) {
    if (e.response?.statusCode == 400) {
      return _serverMessage(e) ?? 'Invalid fee/payment request.';
    }

    if (e.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    if (e.response?.statusCode == 403) {
      return 'You do not have permission to access fees.';
    }

    if (e.response?.statusCode == 404) {
      return 'Fee API endpoint not found.';
    }

    if (e.response?.statusCode == 409) {
      return _serverMessage(e) ?? 'Fee operation conflict.';
    }

    if (e.response?.statusCode == 500) {
      return 'Server error. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Check Spring Boot.';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Server connection timed out.';
    }

    return e.message ?? 'Something went wrong.';
  }

  // ============================================================
  // SERVER ERROR MESSAGE
  // ============================================================

  String? _serverMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }

      if (data['errors'] != null) {
        return data['errors'].toString();
      }
    }

    return null;
  }
}