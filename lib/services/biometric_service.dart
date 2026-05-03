import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();

  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Cek apakah device support biometric (fingerprint)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on Exception catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  /// Cek apakah device memiliki biometric yang terdaftar
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Dapatkan list biometric yang tersedia di device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on Exception catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Autentikasi menggunakan biometric (fingerprint)
  Future<bool> authenticate() async {
    try {
      // Cek apakah device support biometric
      final isSupported = await canCheckBiometrics();
      if (!isSupported) {
        print('Device tidak support biometric');
        return false;
      }

      // Lakukan autentikasi
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari Anda untuk login ke Otomotify',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow fallback ke PIN/pattern jika ada
        ),
      );

      return isAuthenticated;
    } catch (e) {
      print('Error during biometric authentication: $e');
      // Return false daripada throw exception
      return false;
    }
  }

  /// Bersihkan autentikasi (logout)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}
