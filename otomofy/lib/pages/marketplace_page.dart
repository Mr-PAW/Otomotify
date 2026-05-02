import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'marketplace_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  final String userId;

  const MarketplacePage({Key? key, required this.userId}) : super(key: key);

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  // Variabel State buat nyimpen inputan user
  String _searchQuery = "";
  int? _minTahun;
  int? _maxTahun;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minTahunController = TextEditingController();
  final TextEditingController _maxTahunController = TextEditingController();

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // --- FUNGSI MUNCULIN DIALOG FILTER TAHUN ---
  void _showFilterDialog() {
    // Isi textfield sama filter yang lagi aktif (kalo ada)
    _minTahunController.text = _minTahun?.toString() ?? "";
    _maxTahunController.text = _maxTahun?.toString() ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Filter Tahun Mobil",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _minTahunController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: "Tahun Minimum (Min: 1950)",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _maxTahunController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: "Tahun Maksimum (Maks: 2026)",
                  border: OutlineInputBorder(),
                  counterText: "",
                ),
              ),
            ],
          ),
          actions: [
            // Tombol Reset Filter
            TextButton(
              onPressed: () {
                setState(() {
                  _minTahun = null;
                  _maxTahun = null;
                });
                Navigator.pop(context);
              },
              child: Text("Reset", style: TextStyle(color: Colors.red)),
            ),
            // Tombol Terapkan Filter
            ElevatedButton(
              onPressed: () {
                int? parsedMin = int.tryParse(_minTahunController.text);
                int? parsedMax = int.tryParse(_maxTahunController.text);

                // ERROR HANDLING: Rentang 1950 - 2026
                if (parsedMin != null &&
                    (parsedMin < 1950 || parsedMin > 2026)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Tahun Minimum harus antara 1950-2026!"),
                    ),
                  );
                  return;
                }
                if (parsedMax != null &&
                    (parsedMax < 1950 || parsedMax > 2026)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Tahun Maksimum harus antara 1950-2026!"),
                    ),
                  );
                  return;
                }
                if (parsedMin != null &&
                    parsedMax != null &&
                    parsedMin > parsedMax) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Tahun Minimum gak boleh lebih gede dari Maksimum bos!",
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _minTahun = parsedMin;
                  _maxTahun = parsedMax;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3C72),
              ),
              child: Text("Terapkan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // ==========================================
          // BAGIAN ATAS: SEARCH BAR & TOMBOL FILTER
          // ==========================================
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    maxLength: 40, // ERROR HANDLING: Maks 40 Karakter
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value
                            .toLowerCase(); // Dibikin huruf kecil semua biar pencariannya gak case-sensitive
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari merek atau nama mobil...",
                      prefixIcon: Icon(Icons.search),
                      counterText: "", // Ngumpetin angka 0/40 biar rapi
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Tombol Filter (Bakal berubah warna kalo ada filter yg aktif)
                Container(
                  decoration: BoxDecoration(
                    color: (_minTahun != null || _maxTahun != null)
                        ? Colors.orange[100]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: (_minTahun != null || _maxTahun != null)
                          ? Colors.orange[800]
                          : Colors.grey[700],
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // BAGIAN BAWAH: LIST MARKETPLACE (UDAH DI-FILTER)
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mobil')
                  .where(
                    'terjual',
                    isEqualTo: false,
                  ) // Tarik semua yang belum laku
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text("Belum ada iklan mobil di marketplace ini."),
                  );

                // PROSES FILTERING LOKAL DI HP
                var rawDocs = snapshot.data!.docs;
                var filteredDocs = rawDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // 1. Logika Searching (Gabung merek + nama)
                  String merek = (data['merek'] ?? '').toString().toLowerCase();
                  String nama = (data['nama'] ?? '').toString().toLowerCase();
                  String gabunganNama = "$merek $nama";

                  bool matchSearch = gabunganNama.contains(_searchQuery);

                  // 2. Logika Filter Tahun
                  int tahunMobil = data['tahun'] ?? 0;
                  bool matchMinTahun =
                      _minTahun == null || tahunMobil >= _minTahun!;
                  bool matchMaxTahun =
                      _maxTahun == null || tahunMobil <= _maxTahun!;

                  // Mobil ini lolos seleksi kalo menuhi semua syarat
                  return matchSearch && matchMinTahun && matchMaxTahun;
                }).toList();

                // Kalo hasil filter kosong
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Yahh, mobil yang lu cari gak ketemu nih.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Proses Sorting Waktu (Terbaru di atas)
                filteredDocs.sort((a, b) {
                  Timestamp? timeA =
                      (a.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  Timestamp? timeB =
                      (b.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA);
                });

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var mobil = filteredDocs[index];

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
                              builder: (context) => DetailIklanPage(
                                mobil: mobil,
                                userId: widget.userId,
                              ),
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
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 120,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                                        color: Colors.orange[800],
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
          ),
        ],
      ),
    );
  }
}
