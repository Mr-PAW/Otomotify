import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'marketplace_detail_page.dart';

class MarketplacePage extends StatelessWidget {
  final String userId;

  const MarketplacePage({Key? key, required this.userId}) : super(key: key);

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Background agak abu biar cardnya nonjol ala OLX
      body: StreamBuilder<QuerySnapshot>(
        // Query tanpa "where" biar SEMUA iklan dari SEMUA user muncul
        // Diurutin dari yang paling baru diupload
        stream: FirebaseFirestore.instance
            .collection('mobil')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("Belum ada iklan mobil di marketplace ini."),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var mobil = snapshot.data!.docs[index];

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // InkWell biar Card-nya ada animasi material pas diklik
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Pindah ke halaman detail pas diklik
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
                      // KIRI: Gambar Mobil
                      ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: mobil['gambar'] ?? '',
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // KANAN: Detail Teks
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Tahun: ${mobil['tahun']}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Rp ${formatRupiah(mobil['harga'])}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .orange[800], // Warna oren ala e-commerce
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
