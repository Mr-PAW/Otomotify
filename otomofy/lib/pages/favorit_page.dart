import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'marketplace_detail_page.dart'; // Import buat navigasi ke detail
import 'notifikasi_page.dart'; // <-- IMPORT BARU BUAT HALAMAN NOTIF

class FavoritPage extends StatelessWidget {
  final String userId;

  const FavoritPage({Key? key, required this.userId}) : super(key: key);

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // =======================================================
      // APPBAR BARU BUAT NAMPILIN LONCENG NOTIFIKASI
      // =======================================================
      appBar: AppBar(
        title: Text("Favorit Saya"),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E3C72),
        elevation: 1,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifikasi')
                .where('id_user', isEqualTo: userId)
                .where('isRead', isEqualTo: false) // Cari yang belum dibaca aja
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotifikasiPage(userId: userId),
                        ),
                      );
                    },
                  ),
                  if (unreadCount >
                      0) // Munculin titik merah cuma kalo ada notif
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      // =======================================================

      // BODY TETAP SAMA KAYA PUNYA LU
      body: StreamBuilder<QuerySnapshot>(
        // Ambil data dari koleksi 'favorit' sesuai ID user yang login
        stream: FirebaseFirestore.instance
            .collection('favorit')
            .where('id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Belum ada mobil favorit nih.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var favDoc = snapshot.data!.docs[index];
              String idMobil = favDoc['id_mobil'];

              // Ambil detail mobil dari koleksi 'mobil' berdasarkan ID
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('mobil')
                    .doc(idMobil)
                    .get(),
                builder: (context, mobilSnapshot) {
                  if (!mobilSnapshot.hasData || !mobilSnapshot.data!.exists) {
                    return SizedBox(); // Skip kalau data mobil gak ketemu (mungkin udah dihapus owner)
                  }

                  var mobil = mobilSnapshot.data!;

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailIklanPage(mobil: mobil, userId: userId),
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: mobil['gambar'] ?? '',
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.broken_image),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${mobil['merek']} ${mobil['nama']}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Tahun: ${mobil['tahun']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Rp ${formatRupiah(mobil['harga'])}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
