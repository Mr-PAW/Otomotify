import 'dart:convert';
import 'package:http/http.dart' as http;
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
  // Variabel Search & Filter
  String _searchQuery = "";
  int? _minTahun;
  int? _maxTahun;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minTahunController = TextEditingController();
  final TextEditingController _maxTahunController = TextEditingController();

  // Variabel API Mata Uang
  String _selectedCurrency = 'idr';
  Map<String, dynamic> _exchangeRates = {};

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates(); // Tarik data kurs pas halaman dibuka
  }

  // --- FUNGSI TEMBAK API KURS ---
  Future<void> _fetchExchangeRates() async {
    // Ngambil kurs terbaru dengan patokan Rupiah (idr)
    final url = Uri.parse(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/idr.min.json',
    );
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _exchangeRates = data['idr']; // Nyimpen semua kurs dunia
        });
      }
    } catch (e) {
      print("Gagal load API kurs Fawaz Ahmed: $e");
    }
  }

  // --- FUNGSI FORMAT RUPIAH DASAR ---
  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // --- FUNGSI KONVERSI & FORMAT HARGA DINAMIS ---
  String formatHargaDinamis(int hargaIdr) {
    if (_selectedCurrency == 'idr' || _exchangeRates.isEmpty) {
      return "Rp ${formatRupiah(hargaIdr)}";
    }

    // Ambil nilai rate dari API, kalau gak ada kasih 0
    double rate = (_exchangeRates[_selectedCurrency] ?? 0).toDouble();
    double converted = hargaIdr * rate;

    // Setting Simbol
    String symbol = "";
    switch (_selectedCurrency) {
      case 'usd':
        symbol = "\$";
        break;
      case 'eur':
        symbol = "€";
        break;
      case 'jpy':
        symbol = "¥";
        break;
      case 'gbp':
        symbol = "£";
        break;
      case 'cny':
        symbol = "CN¥";
        break; // Chinese Yuan
      case 'myr':
        symbol = "RM";
        break; // Ringgit Malaysia
      case 'sgd':
        symbol = "S\$";
        break; // Dollar Singapore
      case 'thb':
        symbol = "฿";
        break; // Baht Thailand
      case 'aud':
        symbol = "A\$";
        break; // Dollar Australia
      case 'php':
        symbol = "₱";
        break; // Peso Filipina
      default:
        symbol = _selectedCurrency.toUpperCase();
    }

    // Pecah angka biar bisa dikasih koma ribuan (contoh: $ 18,500.00)
    String numStr = converted.toStringAsFixed(2);
    List<String> parts = numStr.split('.');
    String formattedInt = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return "$symbol $formattedInt.${parts[1]}";
  }

  // --- FUNGSI MUNCULIN DIALOG FILTER TAHUN ---
  void _showFilterDialog() {
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
            ElevatedButton(
              onPressed: () {
                int? parsedMin = int.tryParse(_minTahunController.text);
                int? parsedMax = int.tryParse(_maxTahunController.text);

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
          // BAGIAN ATAS: SEARCH BAR, KURS, & FILTER
          // ==========================================
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    maxLength: 40,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari merek atau nama...",
                      prefixIcon: Icon(Icons.search),
                      counterText: "",
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
                SizedBox(width: 8),

                // DROPDOWN MATA UANG API
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      icon: Icon(
                        Icons.monetization_on,
                        color: Color(0xFF1E3C72),
                        size: 18,
                      ),
                      style: TextStyle(
                        color: Color(0xFF1E3C72),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: [
                        DropdownMenuItem(value: 'idr', child: Text(" IDR")),
                        DropdownMenuItem(value: 'usd', child: Text(" USD")),
                        DropdownMenuItem(value: 'eur', child: Text(" EUR")),
                        DropdownMenuItem(value: 'jpy', child: Text(" JPY")),
                        DropdownMenuItem(value: 'gbp', child: Text(" GBP")),
                        DropdownMenuItem(value: 'cny', child: Text(" CNY")),
                        DropdownMenuItem(value: 'myr', child: Text(" MYR")),
                        DropdownMenuItem(value: 'sgd', child: Text(" SGD")),
                        DropdownMenuItem(value: 'thb', child: Text(" THB")),
                        DropdownMenuItem(value: 'aud', child: Text(" AUD")),
                        DropdownMenuItem(value: 'php', child: Text(" PHP")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          if (_exchangeRates.isEmpty && val != 'idr') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Sedang mengambil data kurs dunia, tunggu 1-2 detik lagi ya!",
                                ),
                              ),
                            );
                          } else {
                            setState(() => _selectedCurrency = val);
                          }
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // TOMBOL FILTER TAHUN
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
          // BAGIAN BAWAH: LIST MARKETPLACE
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mobil')
                  .where('terjual', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return Center(
                    child: Text("Belum ada iklan mobil di marketplace ini."),
                  );

                // FILTERING & SEARCHING KODE KEMARIN (Udah Anti-Spasi)
                var rawDocs = snapshot.data!.docs;
                var filteredDocs = rawDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  String merek = (data['merek'] ?? '').toString().toLowerCase();
                  String nama = (data['nama'] ?? '').toString().toLowerCase();
                  String gabunganNamaTanpaSpasi = "$merek$nama".replaceAll(
                    RegExp(r'\s+'),
                    '',
                  );
                  String queryTanpaSpasi = _searchQuery.replaceAll(
                    RegExp(r'\s+'),
                    '',
                  );

                  bool matchSearch = gabunganNamaTanpaSpasi.contains(
                    queryTanpaSpasi,
                  );

                  int tahunMobil = data['tahun'] ?? 0;
                  bool matchMinTahun =
                      _minTahun == null || tahunMobil >= _minTahun!;
                  bool matchMaxTahun =
                      _maxTahun == null || tahunMobil <= _maxTahun!;

                  return matchSearch && matchMinTahun && matchMaxTahun;
                }).toList();

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

                // SORTING TERBARU
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
                                    // PANGGIL FUNGSI DINAMIS DI SINI!
                                    Text(
                                      formatHargaDinamis(mobil['harga']),
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
