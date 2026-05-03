import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../services/biometric_service.dart';
import '../services/biometric_preferences.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();

  // Variabel buat ngontrol password kelihatan atau nggak
  bool _isObscure = true;
  bool _isBiometricAvailable = false;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    bool canCheck = await _biometricService.canCheckBiometrics();
    setState(() {
      _isBiometricAvailable = canCheck;
    });
  }

  String hashInputPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            idUser: matchedUser!.id, // Kirim ID user ke HomePage
            namaUser: matchedUser.nama,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text("Username atau Password salah!"),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _doBiometricLogin() async {
    try {
      print('Starting biometric login...');
      String? enrolledUserId =
          await BiometricPreferences.getEnrolledBiometricUserId();

      if (enrolledUserId == null) {
        print('No enrolled user ID found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sidik jari belum didaftarkan. Silakan login dengan username & password terlebih dahulu, kemudian daftarkan sidik jari di menu Daftar Sidik Jari.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      print('Enrolled user ID: $enrolledUserId, authenticating...');
      bool isAuthenticated = await _biometricService
          .authenticateWithBiometric(reason: 'Login dengan sidik jari');

      print('Authentication result: $isAuthenticated');
      
      if (isAuthenticated) {
        // Find user by ID
        User? matchedUser;
        for (var user in dummyUsers) {
          if (user.id == int.parse(enrolledUserId)) {
            matchedUser = user;
            break;
          }
        }

        if (matchedUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                idUser: matchedUser!.id,
                namaUser: matchedUser.nama,
              ),
            ),
          );
        } else {
          print('User not found for ID: $enrolledUserId');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User tidak ditemukan!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        print('User cancelled biometric authentication');
      }
    } catch (e) {
      print('Error in biometric login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
                    SizedBox(height: 15),
                    Text(
                      "atau",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 15),
                    if (_isBiometricAvailable)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _doBiometricLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7B1FA2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            "LOGIN DENGAN SIDIK JARI",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
