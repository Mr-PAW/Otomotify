import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotifikasiPage extends StatelessWidget {
  final String userId;

  const NotifikasiPage({Key? key, required this.userId}) : super(key: key);

  // FUNGSI BARU: Dialog Warning sebelum hapus
  void _konfirmasiHapus(BuildContext context, String notifId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Hapus Notifikasi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text("Apakah yakin akan menghapus notifikasi ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('notifikasi')
                    .doc(notifId)
                    .delete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Notifikasi dihapus"),
                    backgroundColor: Colors.orange,
                  ),
                );
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
        title: Text("Notifikasi"),
        backgroundColor: Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kita ambil semua notif user ini
        stream: FirebaseFirestore.instance
            .collection('notifikasi')
            .where('id_user', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Belum ada notifikasi.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // TRIK BIAR GAK NGILANG TIAP 2 DETIK:
          // Kita urutin datanya di dalam kodingan aja, jangan di Query Firebase-nya
          // Karena 'createdAt' sering null sebentar pas baru di-upload (syncing)
          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            Timestamp? tA =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            Timestamp? tB =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notif = docs[index];
              bool isRead = notif['isRead'] ?? false;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isRead
                    ? Colors.white
                    : Colors.blue[50], // Tetep biru kalo belom diklik
                elevation: isRead ? 1 : 3,
                child: ListTile(
                  leading: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: isRead ? Colors.grey : Colors.orange,
                  ),
                  title: Text(
                    notif['pesan'],
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(isRead ? "Sudah dibaca" : "Baru saja"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: () =>
                        _konfirmasiHapus(context, notif.id), // Panggil warning
                  ),
                  onTap: () {
                    // SEKARANG CUMA UPDATE isRead, GAK PAKE DELETE
                    if (!isRead) {
                      FirebaseFirestore.instance
                          .collection('notifikasi')
                          .doc(notif.id)
                          .update({'isRead': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
