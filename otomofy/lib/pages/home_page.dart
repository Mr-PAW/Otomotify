import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:otomofy/pages/start_game_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import 'login_page.dart';
import 'jual_page.dart';
import 'marketplace_page.dart';
import 'quiz_page.dart';
import 'favorit_page.dart';
import 'cari_bengkel_page.dart';
import 'home_content_page.dart';
import 'biometric_settings_page.dart';
import 'kesan_pesan_page.dart';
import 'profile_page.dart';
import 'qibla_page.dart';
import 'time_page.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

// =========================================================
// MAIN PAGE (Master Shell)
// =========================================================
class HomePage extends StatefulWidget {
  final int idUser;
  final String namaUser;

  const HomePage({Key? key, required this.idUser, required this.namaUser})
    : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Widget _currentBody;
  String _currentTitle = 'Beranda Otomotify';
  int _bottomNavIndex = 0;

  // ── Reactive drawer state ──────────────────────────────────────────────────
  late String _namaUser;
  String? _profilePicPath;

  StreamSubscription<QuerySnapshot>? _notifSubscription;
  bool _isInitialLoad = true;

  // ── SETUP LOCAL NOTIFICATION ───────────────────────────────────────────────
  final FlutterLocalNotificationsPlugin _localNotifPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _namaUser = widget.namaUser;
    _currentBody = _buildHomeContent();
    _loadProfilePic();

    // Inisialisasi plugin notifikasi, lalu mulai dengarkan Firestore
    _initLocalNotification().then((_) => _mulaiDengerinNotifikasi());
  }

  // FUNGSI: Nyalain mesin notifikasi HP
  Future<void> _initLocalNotification() async {
    // Icon bawaan app flutter biar gak crash
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    // v21 API: named parameter 'settings'
    await _localNotifPlugin.initialize(settings: initSettings);

    // Android 13+ (API 33) wajib minta izin POST_NOTIFICATIONS secara runtime
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  // FUNGSI: Nembak notif ke status bar HP
  Future<void> _tampilNotifBanner(String pesan) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_otomotify_01', // ID Channel
          'Notifikasi Interaksi', // Nama Channel
          channelDescription: 'Notifikasi dari Otomotify untuk interaksi iklan',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          color: Color(0xFF1E3C72),
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // ID unik acak supaya notif tidak menimpa satu sama lain
    // v21 API: named parameters
    await _localNotifPlugin.show(
      id: Random().nextInt(2147483647),
      title: 'Otomotify',
      body: pesan,
      notificationDetails: platformDetails,
    );
  }

  Future<void> _loadProfilePic() async {
    final pic = await ProfileService.getProfilePicPath(
      widget.idUser.toString(),
    );
    if (mounted && pic != null) {
      setState(() => _profilePicPath = pic);
    }
  }

  /// Called by ProfilePage whenever name or picture changes.
  void _onProfileUpdated(String newName, String? newPicPath) {
    setState(() {
      _namaUser = newName;
      if (newPicPath != null) _profilePicPath = newPicPath;
    });
  }

  void _mulaiDengerinNotifikasi() {
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifikasi')
        .where('id_user', isEqualTo: widget.idUser.toString())
        .snapshots()
        .listen((snapshot) {
          if (_isInitialLoad) {
            _isInitialLoad = false;
            return;
          }
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;

              // MUNCULIN BANNER NOTIFIKASI OFFLINE
              _tampilNotifBanner(data['pesan'] ?? 'Ada notifikasi baru!');
            }
          }
        });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  Widget _buildHomeContent() {
    return HomeContentPage(
      idUser: widget.idUser,
      namaUser: _namaUser,
      onNavigate: (page, title) {
        setState(() {
          _currentBody = page;
          _currentTitle = title;
        });
      },
    );
  }

  Widget _buildProfilePage() {
    return ProfilePage(
      userId: widget.idUser.toString(),
      userName: _namaUser,
      onProfileUpdated: _onProfileUpdated,
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _currentBody = _buildHomeContent();
        _currentTitle = 'Beranda Otomotify';
      } else if (index == 1) {
        _currentBody = KesanPesanPage(
          userId: widget.idUser.toString(),
          userName: _namaUser,
        );
        _currentTitle = 'Kesan & Pesan';
      } else if (index == 2) {
        _currentBody = _buildProfilePage();
        _currentTitle = 'Profil Saya';
      }
    });
  }

  void _onDrawerTapped(Widget page, String title) {
    setState(() {
      _currentBody = page;
      _currentTitle = title;
    });
    Navigator.pop(context);
  }

  Future<void> _doLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin mau keluar dari aplikasi Otomotify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _doLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Drawer avatar helper ───────────────────────────────────────────────────
  ImageProvider? get _drawerAvatar {
    if (_profilePicPath != null && File(_profilePicPath!).existsSync()) {
      return FileImage(File(_profilePicPath!));
    }
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),

      // ── DRAWER ────────────────────────────────────────────────────────────
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Profile picture
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _bottomNavIndex = 2;
                        _currentBody = _buildProfilePage();
                        _currentTitle = 'Profil Saya';
                      });
                    },
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white24,
                      backgroundImage: _drawerAvatar,
                      child: _drawerAvatar == null
                          ? const Icon(
                              Icons.person,
                              size: 38,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _namaUser,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap foto untuk edit profil',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── Utama ────────────────────────────────────────────────────────
            _drawerTile(
              icon: Icons.storefront,
              label: 'Marketplace (Beli)',
              onTap: () => _onDrawerTapped(
                MarketplacePage(userId: widget.idUser.toString()),
                'Bursa Mobil',
              ),
            ),
            _drawerTile(
              icon: Icons.add_circle_outline,
              label: 'Jual Mobil',
              onTap: () => _onDrawerTapped(
                JualPage(userId: widget.idUser.toString()),
                'Jual Mobil',
              ),
            ),
            _drawerTile(
              icon: Icons.favorite_border,
              label: 'Favorit Saya',
              onTap: () => _onDrawerTapped(
                FavoritPage(userId: widget.idUser.toString()),
                'Mobil Favorit',
              ),
            ),
            _drawerTile(
              icon: Icons.build_circle_outlined,
              label: 'Cari Bengkel',
              onTap: () =>
                  _onDrawerTapped(const CariBengkelPage(), 'Cari Bengkel'),
            ),

            const Divider(),

            // ── Fitur ────────────────────────────────────────────────────────
            _drawerTile(
              icon: Icons.quiz_outlined,
              label: 'Kuis Otomotif',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.videogame_asset_outlined,
              label: 'Car Maze Mini Game',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.explore,
              label: 'Kompas Kiblat',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QiblaPage()),
                );
              },
            ),
            _drawerTile(
              icon: Icons.access_time,
              label: 'Konversi Waktu',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimePage()),
                );
              },
            ),

            const Divider(),

            // ── Keamanan ─────────────────────────────────────────────────────
            _drawerTile(
              icon: Icons.fingerprint,
              label: 'Daftar Sidik Jari',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BiometricSettingsPage(
                      idUser: widget.idUser.toString(),
                      namaUser: _namaUser,
                    ),
                  ),
                );
              },
            ),

            const Divider(),

            // ── Logout ───────────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _currentBody,

      // ── Bottom Nav ────────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E3C72),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Kesan Pesan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  // ── Helper: consistent drawer list tile ───────────────────────────────────
  Widget _drawerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3C72)),
      title: Text(label),
      onTap: onTap,
    );
  }
}
