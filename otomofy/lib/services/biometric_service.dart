import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  late LocalAuthentication _localAuth;

  factory BiometricService() {
    return _instance;
  }

  BiometricService._internal() {
    _localAuth = LocalAuthentication();
  }

  /// Check if device supports biometric
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  /// Check if device has any biometric enrolled
  Future<bool> deviceSupportsBiometric() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      return canCheck;
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      print('Starting biometric authentication...');
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      print('Biometric authentication result: $isAuthenticated');
      return isAuthenticated;
    } on Exception catch (e) {
      print('Error during biometric authentication: $e');
      rethrow;
    }
  }

  /// Authenticate with biometric or passcode fallback
  Future<bool> authenticateWithBiometricOrPasscode({
    required String reason,
  }) async {
    try {
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
}
