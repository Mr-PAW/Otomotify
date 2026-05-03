import 'package:shared_preferences/shared_preferences.dart';

class BiometricPreferences {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _enrolledBiometricKey = 'enrolled_biometric';

  static Future<void> enableBiometric(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_enrolledBiometricKey, userId);
  }

  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_enrolledBiometricKey);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<String?> getEnrolledBiometricUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_enrolledBiometricKey);
  }
}
