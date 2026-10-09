
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parent_feedback_model.dart';

class ParentFeedbackService {
  // Match this with the base URL used by your admin app.
  static const String baseUrl = 'http://localhost:8080';

  static const String endpoint = '/api/v1/parent-feedback';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('Login session not found. Please log in again.');
    }

    return token;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ParentFeedbackModel>> getAllFeedback() async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Unexpected feedback response from server.');
      }

      return decoded
          .map(
            (item) => ParentFeedbackModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception(
        'Access denied. Please check your School Admin login.',
      );
    }

    throw Exception(
      'Failed to load submissions (${response.statusCode}).',
    );
  }

  Future<void> deleteFeedback(int feedbackId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint/$feedbackId'),
      headers: await _headers(),
    );

    if (response.statusCode == 204 ||
        response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception(
        'Access denied. Please check your School Admin login.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('This submission was not found.');
    }

    throw Exception(
      'Failed to delete submission (${response.statusCode}).',
    );
  }
}
