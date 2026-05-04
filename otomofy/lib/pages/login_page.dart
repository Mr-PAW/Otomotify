import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/biometric_preferences.dart';
import '../models/user.dart';
import 'home_page.dart';
import 'register_page.dart';

// ── Hardcoded example users (no backend needed) ──────────────────────────────
const List<Map<String, dynamic>> _kExampleUsers = [
  {'id': -1, 'name': 'userEx1', 'email': 'userex1@demo.local'},
  {'id': -2, 'name': 'userEx2', 'email': 'userex2@demo.local'},
  {'id': -3, 'name': 'userEx3', 'email': 'userex3@demo.local'},
];

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnrolled = false;

  final BiometricService _biometricService = BiometricService();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnrolled = await BiometricPreferences.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = canCheck;
        _isBiometricEnrolled = isEnrolled;
      });
    }
  }

  // ─── Normal login via backend ─────────────────────────────────────────────
  Future<void> _doLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Email dan password tidak boleh kosong', Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['user'] as User;
        final refreshToken = result['refreshToken'] as String;

        // Keep biometric refresh token up-to-date if enrolled
        await AuthService.updateBiometricEnrollment(
          user: user,
          refreshToken: refreshToken,
        );

        _navigateHome(user);
      } else {
        _showSnack(
          result['message'] ?? 'Login gagal. Coba lagi.',
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Koneksi gagal: ${e.toString()}', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Biometric login ──────────────────────────────────────────────────────
  Future<void> _doBiometricLogin() async {
    // 1. First check if biometric is enrolled
    final isEnrolled = await BiometricPreferences.isBiometricEnabled();
    if (!isEnrolled) {
      _showSnack(
        'Sidik jari belum didaftarkan. Login dulu lalu daftarkan di menu '
        '"Daftar Sidik Jari".',
        Colors.orangeAccent,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    // 2. Prompt biometric
    try {
      final isAuthenticated = await _biometricService.authenticateWithBiometric(
        reason: 'Login dengan sidik jari',
      );

      if (!isAuthenticated || !mounted) return;

      setState(() => _isLoading = true);

      // 3. Exchange stored refresh token for a new access token
      final result = await AuthService.loginWithBiometric();

      if (!mounted) return;

      if (result['success'] == true) {
        _navigateHome(result['user'] as User);
      } else {
        _showSnack(
          result['message'] ?? 'Login biometric gagal.',
          Colors.redAccent,
          duration: const Duration(seconds: 6),
        );
        // Refresh biometric status (may have been disabled on expired token)
        await _checkBiometricStatus();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: ${e.toString()}', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          idUser: user.id,
          namaUser: user.name,
        ),
      ),
    );
  }

  // ─── Example user login (fully offline) ───────────────────────────────────
  void _loginAsExample(Map<String, dynamic> ex) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          idUser: ex['id'] as int,
          namaUser: ex['name'] as String,
        ),
      ),
    );
  }

  void _showSnack(
    String msg,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Colors.black87],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo ──
                      const Icon(
                        Icons.directions_car_filled,
                        size: 64,
                        color: Color(0xFF1E3C72),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'OTOMOTIFY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Color(0xFF1E3C72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marketplace Mobil Terpercaya',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Email ──
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Password ──
                      TextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Login Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),

                      // ── Biometric Button ──
                      if (_isBiometricAvailable) ...[
                        const SizedBox(height: 12),
                        Text(
                          'atau',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _doBiometricLogin,
                            icon: const Icon(
                              Icons.fingerprint,
                              color: Color(0xFF7B1FA2),
                            ),
                            label: Text(
                              _isBiometricEnrolled
                                  ? 'LOGIN DENGAN SIDIK JARI'
                                  : 'SIDIK JARI (BELUM TERDAFTAR)',
                              style: TextStyle(
                                color: _isBiometricEnrolled
                                    ? const Color(0xFF7B1FA2)
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isBiometricEnrolled
                                    ? const Color(0xFF7B1FA2)
                                    : Colors.grey,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // ── Akun Contoh (offline) ──────────────────────────────
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Login Akun Contoh',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _kExampleUsers
                            .map(
                              (ex) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  child: OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _loginAsExample(ex),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey[400]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    child: Text(
                                      ex['name'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // ── Register link ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: Color(0xFF1E3C72),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
