import 'package:shared_preferences/shared_preferences.dart';

/// Manages local biometric enrollment preferences.
///
/// When a user enables biometric login, we store:
///   - A flag marking biometric as enabled
///   - The enrolled user's ID (string, matching the backend `id`)
///   - The enrolled user's display name
///   - The enrolled user's email
///   - The refresh token at the time of enrollment, so the biometric flow
///     can silently re-issue an access token without requiring the password.
class BiometricPreferences {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _enrolledUserIdKey = 'enrolled_biometric_user_id';
  static const String _enrolledUserNameKey = 'enrolled_biometric_user_name';
  static const String _enrolledUserEmailKey = 'enrolled_biometric_user_email';
  static const String _biometricRefreshTokenKey =
      'biometric_refresh_token';

  // ─── Enable ────────────────────────────────────────────────────────────────

  /// Persist biometric enrollment for [userId] with optional metadata.
  ///
  /// [refreshToken] should be the current JWT refresh token so that
  /// [getBiometricRefreshToken] can later retrieve a new access token
  /// on behalf of the user without the password.
  static Future<void> enableBiometric(
    String userId, {
    String? userName,
    String? userEmail,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_enrolledUserIdKey, userId);
    if (userName != null) {
      await prefs.setString(_enrolledUserNameKey, userName);
    }
    if (userEmail != null) {
      await prefs.setString(_enrolledUserEmailKey, userEmail);
    }
    if (refreshToken != null) {
      await prefs.setString(_biometricRefreshTokenKey, refreshToken);
    }
  }

  // ─── Disable ───────────────────────────────────────────────────────────────

  /// Clear all biometric enrollment data.
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_enrolledUserIdKey);
    await prefs.remove(_enrolledUserNameKey);
    await prefs.remove(_enrolledUserEmailKey);
    await prefs.remove(_biometricRefreshTokenKey);
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  /// Returns `true` if the user has previously enrolled biometric login.
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Returns the enrolled user's ID (as stored in the backend), or `null`
  /// if biometric has not been enrolled.
  static Future<String?> getEnrolledBiometricUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_enrolledUserIdKey);
  }

  /// Returns the enrolled user's display name, or `null`.
  static Future<String?> getEnrolledUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_enrolledUserNameKey);
  }

  /// Returns the enrolled user's email, or `null`.
  static Future<String?> getEnrolledUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_enrolledUserEmailKey);
  }

  /// Returns the JWT refresh token stored at enrollment time, or `null`.
  ///
  /// Use this to call `AuthService.refreshToken()` and obtain a fresh
  /// access token without the user's password during a biometric login.
  static Future<String?> getBiometricRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricRefreshTokenKey);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Convenience: returns all enrolled info as a map, or `null` if none.
  static Future<Map<String, String?>?> getEnrolledInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_biometricEnabledKey) ?? false;
    if (!enabled) return null;

    final userId = prefs.getString(_enrolledUserIdKey);
    if (userId == null) return null;

    return {
      'userId': userId,
      'userName': prefs.getString(_enrolledUserNameKey),
      'userEmail': prefs.getString(_enrolledUserEmailKey),
      'refreshToken': prefs.getString(_biometricRefreshTokenKey),
    };
  }
}
