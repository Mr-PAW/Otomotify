import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class EditIklanPage extends StatefulWidget {
  final DocumentSnapshot mobil;

  const EditIklanPage({Key? key, required this.mobil}) : super(key: key);

  @override
  _EditIklanPageState createState() => _EditIklanPageState();
}

class _EditIklanPageState extends State<EditIklanPage> {
  final _merekController = TextEditingController();
  final _namaController = TextEditingController();
  final _tahunController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _isTerjual = false; // Buat nampung status laku/belum

  @override
  void initState() {
    super.initState();
    _merekController.text = widget.mobil['merek'];
    _namaController.text = widget.mobil['nama'];
    _tahunController.text = widget.mobil['tahun'].toString();
    _deskripsiController.text = widget.mobil['deskripsi'];
    _hargaController.text = widget.mobil['harga'].toString();

    // Cek dengan aman apakah field 'terjual' ada di database lu
    var data = widget.mobil.data() as Map<String, dynamic>;
    if (data.containsKey('terjual')) {
      _isTerjual = data['terjual'];
    }
  }

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
        return false;
      }

      return true;
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ AI Scanner offline, foto tidak diverifikasi"),
          backgroundColor: Colors.orange,
        ),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ AI Scanner offline, foto tidak diverifikasi"),
          backgroundColor: Colors.orange,
        ),
      );
      return true;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      File tempFile = File(pickedFile.path);
      if ((tempFile.lengthSync() / 1024) > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Maksimal 500KB bos!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🔥 TAMBAHAN: Cek ke ML API dulu
      bool canUpload = await _checkIfCar(tempFile);
      if (!canUpload) return;

      setState(() => _imageFile = tempFile);
    }
  }

  void _updateIklan() async {
    int? tahun = int.tryParse(_tahunController.text);
    if (tahun == null || tahun < 1950 || tahun > 2026) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tahun salah!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = widget.mobil['gambar'] ?? '';

      if (_imageFile != null) {
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

        if (streamedResponse.statusCode == 200) {
          finalImageUrl = jsonResponse['secure_url'];
        } else {
          throw "Gagal upload: ${jsonResponse['error']['message']}";
        }
      }

      await FirebaseFirestore.instance
          .collection('mobil')
          .doc(widget.mobil.id)
          .update({
            'merek': _merekController.text.trim(),
            'nama': _namaController.text.trim(),
            'tahun': tahun,
            'deskripsi': _deskripsiController.text.trim(),
            'harga': int.tryParse(_hargaController.text) ?? 0,
            'gambar': finalImageUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Iklan berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aduh Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI TANDAI TERJUAL ---
  void _tandaiTerjual() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Tandai Terjual",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          content: Text(
            "Apakah anda yakin mobil ini sudah laku? Iklan akan disembunyikan dari Marketplace namun tetap ada di Iklan Saya.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  // 1. Update status mobil jadi terjual
                  await FirebaseFirestore.instance
                      .collection('mobil')
                      .doc(widget.mobil.id)
                      .update({'terjual': true});

                  // 2. LOGIKA NOTIFIKASI: Cari siapa aja yang nge-favoritin mobil ini
                  var favSnapshot = await FirebaseFirestore.instance
                      .collection('favorit')
                      .where('id_mobil', isEqualTo: widget.mobil.id)
                      .get();

                  // Format harga biar ada titiknya di notif
                  String hargaRupiah = _hargaController.text.replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]}.',
                  );

                  // 3. Looping: Kirim notif ke mereka & Hapus dari favorit mereka
                  for (var doc in favSnapshot.docs) {
                    String idUserYgFavorit = doc['id'];

                    // Bikin notif
                    await FirebaseFirestore.instance.collection('notifikasi').add({
                      'id_user': idUserYgFavorit,
                      'pesan':
                          "${_merekController.text} ${_namaController.text} seharga Rp $hargaRupiah sudah terjual",
                      'isRead': false, // Belum dibaca
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // Hapus dari tabel favorit biar hilang dari halaman mereka
                    await doc.reference.delete();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Yey! Mobil laku terjual."),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Ya, Tandai", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI HAPUS IKLAN ---
  void _hapusIklan() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Hapus Iklan",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            "Apakah anda yakin menghapus iklan ini selamanya? Semua data terkait iklan ini akan hilang tanpa jejak.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx); // Tutup dialog
                setState(() => _isLoading = true);
                try {
                  await FirebaseFirestore.instance
                      .collection('mobil')
                      .doc(widget.mobil.id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Iklan berhasil dihapus."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context); // Balik ke halaman sebelumnya
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: Text("Edit Iklan"),
        backgroundColor: Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: widget.mobil['gambar'] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.broken_image, size: 50),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Klik gambar untuk mengganti foto",
              style: TextStyle(color: Colors.grey, fontSize: 12),
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

            // TOMBOL SIMPAN (Tetep di atas karena ini fitur utama Edit)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateIklan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 16),
            Divider(thickness: 1.5),
            SizedBox(height: 16),

            // LOGIKA DUA TOMBOL DI BAWAH
            _isTerjual
                // KALAU UDAH TERJUAL: Cuma nampilin tombol hapus full-width
                ? SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _hapusIklan,
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        "Hapus Iklan Ini",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                // KALAU BELUM TERJUAL: Tampil tombol terjual (kiri) dan hapus (kanan) sejajar
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _tandaiTerjual,
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            label: Text(
                              "Terjual",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _hapusIklan,
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text(
                              "Hapus",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 30), // Padding bawah biar gak mentok
          ],
        ),
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
