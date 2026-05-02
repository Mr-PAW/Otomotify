import 'dart:io';
import 'dart:convert';
import 'dart:async'; // 🔥 TAMBAHAN: buat TimeoutException
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_iklan_page.dart';

class JualPage extends StatefulWidget {
  final String userId;

  const JualPage({Key? key, required this.userId}) : super(key: key);

  @override
  _JualPageState createState() => _JualPageState();
}

class _JualPageState extends State<JualPage> {
  final _merekController = TextEditingController();
  final _namaController = TextEditingController();
  final _tahunController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // 🔥 TAMBAHAN: Fungsi cek gambar ke ML API
  Future<bool> _checkIfCar(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://upload-reheat-skeptic.ngrok-free.dev/predict'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send().timeout(Duration(seconds: 10));
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

      if (result['is_car'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Sepertinya bukan foto mobil, coba foto lain!"),
            backgroundColor: Colors.red,
          ),
        );
        return false; // Batalin, bukan mobil
      }

      return true; // Lolos, ini mobil
    } on TimeoutException {
      // API timeout → tetep allow upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ AI Scanner offline, foto tidak diverifikasi"),
          backgroundColor: Colors.orange,
        ),
      );
      return true;
    } catch (e) {
      // API error/mati → tetep allow upload
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ AI Scanner offline, foto tidak diverifikasi"),
          backgroundColor: Colors.orange,
        ),
      );
      return true;
    }
  }

  // 🔥 MODIFIKASI: _pickImage sekarang manggil _checkIfCar dulu
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      File tempFile = File(pickedFile.path);
      int sizeInBytes = tempFile.lengthSync();
      double sizeInKb = sizeInBytes / 1024;

      // Cek ukuran dulu (kode lo yang existing, nggak diubah)
      if (sizeInKb > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gambar kegedean bos! Maksimal 500KB. (Ukuran foto lu: ${sizeInKb.toStringAsFixed(0)}KB)",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🔥 TAMBAHAN: Cek ke ML API dulu sebelum setState
      bool canUpload = await _checkIfCar(tempFile);
      if (!canUpload) return; // Batalin kalau bukan mobil

      setState(() {
        _imageFile = tempFile;
      });
    }
  }

  // Fungsi submit ini TIDAK DIUBAH sama sekali
  void _submitIklan() async {
    int? tahun = int.tryParse(_tahunController.text);
    if (tahun == null || tahun < 1950 || tahun > 2026) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tahun harus antara 1950 - 2026!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_merekController.text.isEmpty ||
        _namaController.text.isEmpty ||
        _hargaController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Semua kolom dan gambar wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dbqlvsfmc/image/upload'),
      );
      request.fields['upload_preset'] = 'testAA';
      request.files.add(
        await http.MultipartFile.fromPath('file', _imageFile!.path),
      );

      var streamedResponse = await request.send();
      var jsonResponse = json.decode(
        await streamedResponse.stream.bytesToString(),
      );

      if (streamedResponse.statusCode != 200) {
        throw "Gagal upload gambar: ${jsonResponse['error']['message']}";
      }

      String downloadUrl = jsonResponse['secure_url'];

      await FirebaseFirestore.instance.collection('mobil').add({
        'merek': _merekController.text,
        'nama': _namaController.text,
        'tahun': tahun,
        'deskripsi': _deskripsiController.text,
        'harga': int.tryParse(_hargaController.text) ?? 0,
        'gambar': downloadUrl,
        'id': widget.userId,
        'terjual': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _merekController.clear();
      _namaController.clear();
      _tahunController.clear();
      _deskripsiController.clear();
      _hargaController.clear();
      setState(() => _imageFile = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Iklan berhasil ditambahkan!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Semua widget build di bawah ini TIDAK DIUBAH sama sekali
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: Color(0xFF1E3C72),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1E3C72),
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: "Iklan Saya"),
              Tab(icon: Icon(Icons.add_circle_outline), text: "Tambah Iklan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildIklanSayaTab(), _buildTambahIklanTab()],
        ),
      ),
    );
  }

  Widget _buildIklanSayaTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mobil')
          .where('id', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(child: Text("Lu belum pasang iklan mobil nih."));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var mobil = snapshot.data!.docs[index];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditIklanPage(mobil: mobil),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: mobil['gambar'] ?? '',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                              Text("Gagal Load Gambar"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "${mobil['merek']} ${mobil['nama']}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.edit, color: Colors.grey, size: 20),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Tahun: ${mobil['tahun']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Rp ${formatRupiah(mobil['harga'])}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
  }

  Widget _buildTambahIklanTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 8),
                        Text("Upload Foto Mobil (Maks 500KB)"),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            "Merek Mobil",
            _merekController,
            Icons.branding_watermark,
            maxLength: 15,
          ),
          _buildTextField(
            "Nama Mobil",
            _namaController,
            Icons.directions_car,
            maxLength: 25,
          ),
          _buildTextField(
            "Tahun",
            _tahunController,
            Icons.date_range,
            isNumber: true,
            maxLength: 4,
          ),
          _buildTextField(
            "Harga (Angka saja)",
            _hargaController,
            Icons.monetization_on,
            isNumber: true,
          ),
          TextField(
            controller: _deskripsiController,
            maxLines: 3,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: "Deskripsi Singkat",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitIklan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3C72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Pasang Iklan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          counterText: "",
        ),
      ),
    );
  }
}
