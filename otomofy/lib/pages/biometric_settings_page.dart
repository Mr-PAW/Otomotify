import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../services/biometric_preferences.dart';
import '../services/auth_service.dart';

class BiometricSettingsPage extends StatefulWidget {
  final String idUser;
  final String namaUser;

  const BiometricSettingsPage({
    Key? key,
    required this.idUser,
    required this.namaUser,
  }) : super(key: key);

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  final BiometricService _biometricService = BiometricService();
  bool _isDeviceSupported = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeBiometricSettings();
  }

  Future<void> _initializeBiometricSettings() async {
    try {
      bool isSupported = await _biometricService.deviceSupportsBiometric();
      bool canCheck = await _biometricService.canCheckBiometrics();
      List<BiometricType> available = await _biometricService
          .getAvailableBiometrics();
      bool isEnabled = await BiometricPreferences.isBiometricEnabled();

      setState(() {
        _isDeviceSupported = isSupported && canCheck;
        _availableBiometrics = available;
        _isBiometricEnabled = isEnabled;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing biometric settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric
      try {
        bool isAuthenticated = await _biometricService
            .authenticateWithBiometric(
              reason: 'Scan sidik jari untuk daftar login',
            );

        if (isAuthenticated) {
          // Fetch the current refresh token to store with biometric enrollment
          final refreshToken = await AuthService.getRefreshToken();
          await BiometricPreferences.enableBiometric(
            widget.idUser,
            userName: widget.namaUser,
            refreshToken: refreshToken,
          );
          setState(() {
            _isBiometricEnabled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text('Sidik jari berhasil didaftarkan')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // User cancelled authentication
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pendaftaran sidik jari dibatalkan'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reset toggle switch state
          setState(() {});
        }
      } catch (e) {
        print('Error in _toggleBiometric: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reset toggle switch state on error
        setState(() {});
      }
    } else {
      // Disable biometric
      await BiometricPreferences.disableBiometric();
      setState(() {
        _isBiometricEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sidik jari berhasil dihapus'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testBiometric() async {
    try {
      bool isAuthenticated = await _biometricService.authenticateWithBiometric(
        reason: 'Tes sidik jari',
      );

      if (isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tes sidik jari berhasil!'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tes sidik jari gagal: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _getBiometricTypeLabel(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFFF7F2FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF8FF),
      appBar: AppBar(
        title: Text('Daftar Sidik Jari', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E3C72),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(
                      icon: Icons.smartphone,
                      title: 'Status Device',
                      subtitle: _isDeviceSupported
                          ? 'Perangkat mendukung biometric'
                          : 'Perangkat tidak mendukung biometric',
                    ),
                    SizedBox(height: 16),

                    if (_isDeviceSupported) ...[
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F2FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.fingerprint, color: Colors.black54, size: 28),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aktifkan Login Sidik Jari',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Akun: ${widget.namaUser}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isBiometricEnabled,
                              onChanged: _toggleBiometric,
                              activeColor: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.verified_user_outlined,
                        title: 'User Biometric Tersimpan',
                        subtitle: _isBiometricEnabled ? widget.namaUser : 'Belum ada biometric tersimpan',
                      ),
                      SizedBox(height: 16),

                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7F2FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar Jenis Biometric Tersedia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (_availableBiometrics.isEmpty)
                              Text(
                                'Tidak ada biometric tersedia',
                                style: TextStyle(color: Colors.black54),
                              )
                            else
                              ..._availableBiometrics.map((type) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20, color: Colors.black87),
                                    SizedBox(width: 12),
                                    Text(
                                      _getBiometricTypeLabel(type),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      InkWell(
                        onTap: _testBiometric,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F2FA),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fingerprint, color: Color(0xFF6750A4)),
                              SizedBox(width: 8),
                              Text(
                                'Tes Sidik Jari',
                                style: TextStyle(
                                  color: Color(0xFF6750A4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
