import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart'; // Ini file yang barusan lu generate!
import 'pages/login_page.dart';

void main() async {
  // 1. Ini wajib dipanggil sebelum Firebase jalan
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables dari file .env
  await dotenv.load(fileName: '.env');

  // 3. Ini kode buat nge-connect aplikasi lu ke project Firebase lu
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Otomotify',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Aplikasi tetep mulai dari halaman login
      home: LoginPage(),
    );
  }
}
