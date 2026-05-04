import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'biometric_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.18.225:3000/api/auth';
  static const _storage = FlutterSecureStorage();

  // ========== TOKEN MANAGEMENT ==========

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> deleteTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // ========== AUTH API ==========

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return {'success': true, 'user': User.fromJson(data['user'])};
    } else {
      return {'success': false, 'message': data['message']};
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return {
        'success': true,
        'user': User.fromJson(data['user']),
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
      };
    } else {
      return {'success': false, 'message': data['message']};
    }
  }

  // ─── Biometric Login ────────────────────────────────────────────────────────
  /// Silently reissue tokens using the refresh token stored at biometric
  /// enrollment time. Returns the current [User] on success, or `null` if the
  /// refresh token is expired / invalid (caller should ask the user to
  /// re-login with password and re-enroll biometric).
  static Future<Map<String, dynamic>> loginWithBiometric() async {
    final storedRefresh = await BiometricPreferences.getBiometricRefreshToken();

    if (storedRefresh == null) {
      return {
        'success': false,
        'message':
            'Refresh token biometric tidak ditemukan. '
            'Silakan login dengan email & password terlebih dahulu.',
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': storedRefresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'] as String;

      // Persist the new access token (keep the biometric refresh token as-is)
      await _storage.write(key: 'access_token', value: newAccessToken);

      // Fetch the full user profile with the fresh access token
      final user = await _getMeWithToken(newAccessToken);
      if (user != null) {
        return {'success': true, 'user': user, 'accessToken': newAccessToken};
      }

      return {
        'success': false,
        'message': 'Gagal mengambil data pengguna setelah refresh.',
      };
    } else {
      // The stored refresh token is expired – wipe biometric enrollment so
      // the user gets a friendly nudge to re-enroll.
      await BiometricPreferences.disableBiometric();
      return {
        'success': false,
        'message':
            'Sesi biometric telah kedaluwarsa. Silakan login ulang dengan email & password.',
      };
    }
  }

  /// Update the refresh token stored inside biometric preferences after a
  /// successful normal login, so the biometric session stays fresh.
  static Future<void> updateBiometricEnrollment({
    required User user,
    required String refreshToken,
  }) async {
    final isEnrolled = await BiometricPreferences.isBiometricEnabled();
    if (!isEnrolled) return;

    // Re-store with the latest refresh token
    await BiometricPreferences.enableBiometric(
      user.id.toString(),
      userName: user.name,
      userEmail: user.email,
      refreshToken: refreshToken,
    );
  }

  // Get current user (using in-memory access token)
  static Future<User?> getMe() async {
    final token = await getAccessToken();
    if (token == null) return null;
    return _getMeWithToken(token);
  }

  static Future<User?> _getMeWithToken(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    }
    return null;
  }

  // ─── Profile Update ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi habis, silakan login ulang'};
    }

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'user': User.fromJson(data['user'])};
    } else {
      return {'success': false, 'message': data['message']};
    }
  }

  // ─── Change Password ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi habis, silakan login ulang'};
    }

    final response = await http.put(
      Uri.parse('$baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': data['message']};
    }
  }

  // Logout
  static Future<void> logout() async {
    await deleteTokens();
  }

  // Refresh token
  static Future<bool> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'access_token', value: data['accessToken']);
      return true;
    }
    return false;
  }
}
