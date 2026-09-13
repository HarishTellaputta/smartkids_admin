
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  // =========================
  // REGISTER
  // =========================

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER RESPONSE: ${response.data}');
    } on DioException catch (e) {
      print('REGISTER ERROR: ${e.response?.data}');
      print('REGISTER STATUS: ${e.response?.statusCode}');

      throw Exception(
        e.response?.data?['message'] ?? 'Registration failed',
      );
    }
  }

  // =========================
  // LOGIN
  // =========================

  Future<String> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN RESPONSE: ${response.data}');

      final token = response.data['token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token not received');
      }

      final jwtToken = token.toString();

      // Save JWT
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'jwt_token',
        jwtToken,
      );

      print('================================');
      print('JWT SAVED SUCCESSFULLY');
      print('JWT LENGTH: ${jwtToken.length}');
      print('================================');

      return jwtToken;
    } on DioException catch (e) {
      print('LOGIN ERROR: ${e.response?.data}');
      print('LOGIN STATUS: ${e.response?.statusCode}');

      throw Exception(
        e.response?.data?['message'] ?? 'Login failed',
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    try {
      final response = await apiClient.dio.post(
        '/auth/logout',
      );

      print('LOGOUT STATUS: ${response.statusCode}');
      print('LOGOUT RESPONSE: ${response.data}');

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('jwt_token');

      print('JWT REMOVED');
    } on DioException catch (e) {
      print('LOGOUT ERROR: ${e.response?.data}');
      print('LOGOUT STATUS: ${e.response?.statusCode}');

      throw Exception(
        e.response?.data?['message'] ?? 'Logout failed',
      );
    }
  }
}

