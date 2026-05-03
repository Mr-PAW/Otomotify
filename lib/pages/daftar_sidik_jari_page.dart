import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/biometric_preferences_service.dart';
import '../services/biometric_service.dart';

class DaftarSidikJariPage extends StatefulWidget {
  final String currentUsername;

  const DaftarSidikJariPage({Key? key, required this.currentUsername})
    : super(key: key);

  @override
  State<DaftarSidikJariPage> createState() => _DaftarSidikJariPageState();
}

class _DaftarSidikJariPageState extends State<DaftarSidikJariPage> {
  final BiometricService _biometricService = BiometricService();
  final BiometricPreferencesService _preferencesService =
      BiometricPreferencesService();

  bool _isLoading = true;
  bool _isTesting = false;
  bool _isDeviceSupported = false;
  bool _isEnabledForCurrentUser = false;
  String? _lastBiometricUser;
  List<BiometricType> _availableBiometrics = const [];

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final availableBiometrics = await _biometricService
        .getAvailableBiometrics();
    final lastUser = await _preferencesService.getLastBiometricUser();
    final isEnabled = await _preferencesService.isBiometricEnabledForUser(
      widget.currentUsername,
    );

    if (!mounted) return;

    setState(() {
      _isDeviceSupported = isSupported;
      _availableBiometrics = availableBiometrics;
      _lastBiometricUser = lastUser;
      _isEnabledForCurrentUser = isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _preferencesService.enableBiometricForUser(widget.currentUsername);
      await _preferencesService.setLastBiometricUser(widget.currentUsername);
    } else {
      await _preferencesService.disableBiometricForUser(widget.currentUsername);
      if (_lastBiometricUser?.toLowerCase() ==
          widget.currentUsername.toLowerCase()) {
        await _preferencesService.clearLastBiometricUser();
      }
    }

    await _loadBiometricState();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Sidik jari diaktifkan untuk ${widget.currentUsername}'
              : 'Sidik jari dinonaktifkan untuk ${widget.currentUsername}',
        ),
      ),
    );
  }

  Future<void> _testBiometric() async {
    setState(() {
      _isTesting = true;
    });

    final authenticated = await _biometricService.authenticate();

    if (!mounted) return;

    setState(() {
      _isTesting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authenticated
              ? 'Verifikasi sidik jari berhasil.'
              : 'Verifikasi sidik jari gagal atau dibatalkan.',
        ),
      ),
    );
  }

  String _formatBiometricType(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.strong:
        return 'Biometric Strong';
      case BiometricType.weak:
        return 'Biometric Weak';
      case BiometricType.iris:
        return 'Iris';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadBiometricState,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text('Status Device'),
              subtitle: Text(
                _isDeviceSupported
                    ? 'Perangkat mendukung biometric'
                    : 'Perangkat belum mendukung biometric',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _isEnabledForCurrentUser,
              onChanged: _isDeviceSupported ? _setBiometricEnabled : null,
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Aktifkan Login Sidik Jari'),
              subtitle: Text('Akun: ${widget.currentUsername}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('User Biometric Tersimpan'),
              subtitle: Text(_lastBiometricUser ?? '-'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Jenis Biometric Tersedia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_availableBiometrics.isEmpty)
                    const Text(
                      'Belum ada biometric yang terdeteksi di perangkat.',
                    )
                  else
                    ..._availableBiometrics.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(_formatBiometricType(type)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDeviceSupported && !_isTesting
                  ? _testBiometric
                  : null,
              icon: _isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(_isTesting ? 'Memverifikasi...' : 'Tes Sidik Jari'),
            ),
          ),
        ],
      ),
    );
  }
}
