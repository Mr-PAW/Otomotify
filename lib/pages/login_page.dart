import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../services/biometric_service.dart';
import '../services/biometric_preferences_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final BiometricService _biometricService = BiometricService();
  final BiometricPreferencesService _preferencesService =
      BiometricPreferencesService();

  // Variabel buat ngontrol password kelihatan atau nggak
  bool _isObscure = true;
  bool _isBiometricAvailable = false;
  bool _isAuthenticating = false;

  String hashInputPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  // Cek apakah biometric tersedia di device
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isDeviceSupported();
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  // Login menggunakan biometric (sidik jari)
  Future<void> _doBiometricLogin() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final isAuthenticated = await _biometricService.authenticate();

      if (isAuthenticated) {
        // Ambil username user terakhir yang login dengan biometric
        final lastUser = await _preferencesService.getLastBiometricUser();

        if (lastUser != null && lastUser.isNotEmpty) {
          // Cari user berdasarkan username
          User? foundUser;
          for (var user in dummyUsers) {
            if (user.username.toLowerCase() == lastUser.toLowerCase()) {
              foundUser = user;
              break;
            }
          }

          if (foundUser != null) {
            _navigateToHome(foundUser);
          } else {
            _showErrorSnackbar("User tidak ditemukan!");
          }
        } else {
          _showErrorSnackbar(
            "Silakan login dengan username dan password terlebih dahulu!",
          );
        }
      } else {
        _showErrorSnackbar("Autentikasi biometric gagal!");
      }
    } catch (e) {
      _showErrorSnackbar("Error: $e");
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void doLogin() {
    String inputUser = userController.text;
    String inputPassHashed = hashInputPassword(passController.text);

    // Kita bikin variabel buat nyimpen user yang cocok
    User? matchedUser;

    // Looping buat nyari user yang username dan passwordnya pas
    for (var user in dummyUsers) {
      if (user.username.toLowerCase() == inputUser.toLowerCase().trim() &&
          user.password.toLowerCase() == inputPassHashed.toLowerCase()) {
        matchedUser = user;
        break; // Kalau ketemu, stop pencarian
      }
    }

    if (matchedUser != null) {
      // Simpan username user untuk biometric login selanjutnya
      _preferencesService.setLastBiometricUser(matchedUser.username);
      _navigateToHome(matchedUser);
    } else {
      _showErrorSnackbar("Username atau Password salah!");
    }
  }

  // Helper method untuk navigasi ke HomePage
  void _navigateToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(idUser: user.id, namaUser: user.nama),
      ),
    );
  }

  // Helper method untuk menampilkan error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Colors.black87],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Container(
                padding: EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_filled,
                      size: 60,
                      color: Color(0xFF1E3C72),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "OTOMOTIFY",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFF1E3C72),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Marketplace Mobil Terpercaya",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 40),

                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 20),

                    // TextField Password dengan Icon Mata
                    TextField(
                      controller: passController,
                      obscureText: _isObscure, // Dikontrol dari variabel state
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        // Ini icon matanya (Suffix Icon letaknya di kanan)
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            // setState buat me-render ulang UI saat nilai berubah
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: doLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E3C72),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Biometric Login Button
                    if (_isBiometricAvailable) ...[
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "atau",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : _doBiometricLogin,
                          icon: _isAuthenticating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.fingerprint, size: 24),
                          label: Text(
                            _isAuthenticating
                                ? "Mendeteksi..."
                                : "LOGIN DENGAN SIDIK JARI",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2A5298),
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
