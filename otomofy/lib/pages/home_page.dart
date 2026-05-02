import 'package:flutter/material.dart';
import 'package:otomofy/pages/start_game_screen.dart';
import 'login_page.dart';
import 'jual_page.dart';
import 'marketplace_page.dart';
import 'quiz_page.dart';
import 'favorit_page.dart';
import 'dart:async'; // WAJIB buat StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// 2. PLACEHOLDER UNTUK MENU BOTTOM NAV (BAWAH)
// =========================================================
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      "Halaman Home Utama (Semua ada di sini)",
      style: TextStyle(fontSize: 20),
    ),
  );
}

class KesanPesanContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text("Halaman Kesan & Pesan Matkul", style: TextStyle(fontSize: 20)),
  );
}

class ProfileContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text("Halaman Profil", style: TextStyle(fontSize: 20)));
}

// =========================================================
// 3. MAIN PAGE (Master Shell)
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
  // Variabel buat nyimpen UI mana yang lagi tampil
  Widget _currentBody = HomeContent();
  String _currentTitle = 'Beranda Otomotify';

  StreamSubscription<QuerySnapshot>? _notifSubscription;
  bool _isInitialLoad =
      true; // Trik biar pas baru buka app gak langsung dispam pop-up

  @override
  void initState() {
    super.initState();
    _mulaiDengerinNotifikasi();
  }

  void _mulaiDengerinNotifikasi() {
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifikasi')
        .where('id_user', isEqualTo: widget.idUser.toString())
        .snapshots()
        .listen((snapshot) {
          // Kalo ini pertama kali app ngeload data, lewatin aja biar gak spam
          if (_isInitialLoad) {
            _isInitialLoad = false;
            return;
          }

          // Ngecek apakah ada dokumen BARU yang masuk
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data() as Map<String, dynamic>;

              // Munculin Pop-Up Melayang (Floating SnackBar)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['pesan'] ?? 'Ada notifikasi baru!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange[800], // Warna oren khas notif
                  behavior: SnackBarBehavior
                      .floating, // Biar ngambang kayak pop-up beneran
                  margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: Duration(
                    seconds: 4,
                  ), // Ilang sendiri setelah 4 detik
                  action: SnackBarAction(
                    label: 'TUTUP',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          }
        });
  }

  @override
  void dispose() {
    // Matiin CCTV kalo user logout atau keluar aplikasi biar gak bocor memori
    _notifSubscription?.cancel();
    super.dispose();
  }

  // Cuma buat ngontrol warna biru di tombol navbar bawah
  int _bottomNavIndex = 0;

  // Fungsi ganti halaman dari BOTTOM NAV
  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index; // Pindah warna tombol
      if (index == 0) {
        _currentBody = HomeContent();
        _currentTitle = 'Beranda Otomotify';
      } else if (index == 1) {
        _currentBody = KesanPesanContent();
        _currentTitle = 'Kesan & Pesan Matkul';
      } else if (index == 2) {
        _currentBody = ProfileContent();
        _currentTitle = 'Profil Saya';
      }
    });
  }

  // Fungsi ganti halaman dari DRAWER (Hamburger)
  void _onDrawerTapped(Widget page, String title) {
    setState(() {
      _currentBody = page;
      _currentTitle = title;
    });
    Navigator.pop(context); // Tutup drawer otomatis
  }

  void _doLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Konfirmasi Logout"),
          content: Text("Yakin mau keluar dari aplikasi Otomotify?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _doLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text("Keluar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),

      // === DRAWER (MENU SAMPING) ===
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Halo, ${widget.namaUser}!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Marketplace
            ListTile(
              leading: Icon(Icons.storefront),
              title: Text('Marketplace (Beli)'),
              onTap: () => _onDrawerTapped(
                MarketplacePage(userId: widget.idUser.toString()),
                'Bursa Mobil',
              ),
            ),

            // Menu Jual Mobil
            ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Jual Mobil'),
              onTap: () => _onDrawerTapped(
                JualPage(userId: widget.idUser.toString()),
                'Jual Mobil',
              ),
            ),

            // Menu Favorit
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorit Saya'),
              onTap: () => _onDrawerTapped(
                FavoritPage(userId: widget.idUser.toString()),
                'Mobil Favorit',
              ),
            ),

            Divider(),
            
            // Menu Kuis Otomotif
            ListTile(
              leading: Icon(Icons.quiz_outlined),
              title: Text('Kuis Otomotif'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer dulu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizScreen()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.quiz_outlined),
              title: Text('Car Maze Mini Game'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer dulu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),

            Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),

      // === BODY (Isi Halaman) ===
      body: _currentBody,

      // === BOTTOM NAVIGATION BAR ===
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1E3C72),
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
}
