import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DetailIklanPage extends StatefulWidget {
  final DocumentSnapshot mobil;
  final String userId;

  const DetailIklanPage({Key? key, required this.mobil, required this.userId})
    : super(key: key);

  @override
  _DetailIklanPageState createState() => _DetailIklanPageState();
}

class _DetailIklanPageState extends State<DetailIklanPage> {
  bool _isLoadingFav = false;

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Fungsi 1: Nambah ke Favorit (Langsung eksekusi tanpa warning)
  void _tambahKeFavorit() async {
    setState(() => _isLoadingFav = true);
    try {
      await FirebaseFirestore.instance.collection('favorit').add({
        'id_mobil': widget.mobil.id,
        'id': widget.userId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil ditambahkan ke Favorit! ❤️"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menambah favorit: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingFav = false);
    }
  }

  // Fungsi 2: Hapus dari Favorit (Munculin Pop-up Dialog dulu)
  void _hapusDariFavorit(String favDocId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Hapus Favorit",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text("Apakah anda yakin menghapus iklan ini dari favorit?"),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // Tutup dialog doang
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog dulu

                // Eksekusi hapus di Firebase
                setState(() => _isLoadingFav = true);
                try {
                  await FirebaseFirestore.instance
                      .collection('favorit')
                      .doc(favDocId)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Dihapus dari daftar Favorit."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() => _isLoadingFav = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
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
        title: Text("Detail Iklan"),
        backgroundColor: Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: widget.mobil['gambar'] ?? '',
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                color: Colors.grey[200],
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, size: 50),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.mobil['merek']} ${widget.mobil['nama']}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tahun: ${widget.mobil['tahun']}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Rp ${formatRupiah(widget.mobil['harga'])}",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),

                  Divider(height: 40, thickness: 1),

                  Text(
                    "Deskripsi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.mobil['deskripsi'] ?? "Tidak ada deskripsi.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // KEAJAIBAN STREAMBUILDER DI TOMBOL FAVORIT
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        // Nyari apakah mobil ini ada di tabel favorit punya user yang lagi login
        stream: FirebaseFirestore.instance
            .collection('favorit')
            .where('id_mobil', isEqualTo: widget.mobil.id)
            .where('id', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          bool isFavorit = false;
          String? favDocId;

          // Kalau datanya ketemu, berarti udah difavoritin
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            isFavorit = true;
            favDocId = snapshot
                .data!
                .docs
                .first
                .id; // Ambil ID barisnya buat dihapus nanti
          }

          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                // Logika klik: kalau loading matiin tombol, kalo isFavorit arahin ke fungsi hapus, kalo engga ke fungsi tambah
                onPressed: _isLoadingFav
                    ? null
                    : (isFavorit
                          ? () => _hapusDariFavorit(favDocId!)
                          : _tambahKeFavorit),

                // Logika Icon: Kalo favorit iconnya solid & merah, kalo belum iconnya outline & putih
                icon: _isLoadingFav
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: isFavorit ? Colors.redAccent : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isFavorit ? Icons.favorite : Icons.favorite_border,
                        color: isFavorit ? Colors.redAccent : Colors.white,
                      ),

                label: Text(
                  _isLoadingFav
                      ? "Memproses..."
                      : (isFavorit
                            ? "Hapus dari Favorit"
                            : "Tambahkan ke Favorit"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isFavorit ? Colors.redAccent : Colors.white,
                  ),
                ),

                // Logika Warna Tombol
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFavorit ? Colors.white : Colors.redAccent,
                  side: isFavorit
                      ? BorderSide(color: Colors.redAccent, width: 2)
                      : BorderSide.none, // Outline merah kalau udah favorit
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
