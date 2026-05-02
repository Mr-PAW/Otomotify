import 'package:flutter/material.dart';
import 'login_page.dart';
import 'jual_page.dart'; // Import file JualPage lu yang asli

// =========================================================
// 1. PLACEHOLDER UNTUK MENU DRAWER (SAMPING)
// =========================================================
class MarketplacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Text("Halaman Beli / Marketplace", style: TextStyle(fontSize: 20)),
  );
}

// NOTE: Placeholder class JualPage udah gua HAPUS karena udah import dari atas.

class FavoritPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text("Halaman Favorit", style: TextStyle(fontSize: 20)));
}

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
              onTap: () => _onDrawerTapped(MarketplacePage(), 'Bursa Mobil'),
            ),

            // Menu Jual Mobil
            ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Jual Mobil'),
              // Lempar widget.idUser.toString() ke JualPage yang bener
              onTap: () => _onDrawerTapped(
                JualPage(userId: widget.idUser.toString()),
                'Jual Mobil',
              ),
            ),

            // Menu Favorit
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorit Saya'),
              onTap: () => _onDrawerTapped(FavoritPage(), 'Mobil Favorit'),
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
