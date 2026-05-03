import 'package:shared_preferences/shared_preferences.dart';

class BiometricPreferencesService {
  static final BiometricPreferencesService _instance =
      BiometricPreferencesService._internal();

  factory BiometricPreferencesService() => _instance;
  BiometricPreferencesService._internal();

  static const String _lastUserKey = 'last_biometric_user';
  static const String _biometricEnabledKey = 'biometric_enabled_';

  /// Simpan username user terakhir yang login dengan biometric
  Future<void> setLastBiometricUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserKey, username);
  }

  /// Ambil username user terakhir yang login dengan biometric
  Future<String?> getLastBiometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUserKey);
  }

  /// Hapus data user terakhir (logout)
  Future<void> clearLastBiometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserKey);
  }

  /// Enable biometric login untuk user tertentu
  Future<void> enableBiometricForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_biometricEnabledKey$username', true);
  }

  /// Disable biometric login untuk user tertentu
  Future<void> disableBiometricForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_biometricEnabledKey$username', false);
  }

  /// Cek apakah biometric enabled untuk user tertentu
  Future<bool> isBiometricEnabledForUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_biometricEnabledKey$username') ?? false;
  }
}
