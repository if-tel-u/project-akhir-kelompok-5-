import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../../config/constants/api_constants.dart';
import 'dart:convert';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.post(registerEndpoint, {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response['status'] == 'success') {
        final user = UserModel.fromJson(response['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        return user;
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post(loginEndpoint, {
        'email': email,
        'password': password,
      });

      if (response['status'] == 'success') {
        final user = UserModel.fromJson(response['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);
        return user;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      // Simulate fetching user data with token (ganti dengan API call kalo backend support)
      // Contoh: final response = await _apiClient.get('/user', headers: {'Authorization': 'Bearer $token'});
      // Untuk sekarang, asumsikan token berisi user ID
      final decodedToken = jsonDecode(utf8.decode(base64Decode(token)));
      final userId = decodedToken['user_id'];

      // Dummy user fetch (ganti dengan API call ke /api/user nanti)
      return UserModel(
        id: userId,
        name: 'User', // Ganti dengan data dari API
        email: 'user@example.com', // Ganti dengan data dari API
      );
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> updateProfile(
    String userId,
    String name, {
    String? avatarUrl,
  }) async {
    try {
      final response = await _apiClient.put('$usersEndpoint/$userId', {
        'name': name,
        'avatar_url': avatarUrl,
      });

      if (response['status'] == 'success') {
        final user = UserModel.fromJson(response['data']);
        return user;
      }
      throw Exception(response['message'] ?? 'Failed to update profile');
    } catch (e) {
      throw Exception('Profile update error: $e');
    }
  }

  Future<bool> deleteAccount(String userId) async {
    try {
      final response = await _apiClient.delete('$usersEndpoint/$userId', {});

      if (response['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        return true;
      }
      throw Exception(response['message'] ?? 'Failed to delete account');
    } catch (e) {
      throw Exception('Account deletion error: $e');
    }
  }
}
