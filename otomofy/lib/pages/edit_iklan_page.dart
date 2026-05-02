import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _merekController.text = widget.mobil['merek'];
    _namaController.text = widget.mobil['nama'];
    _tahunController.text = widget.mobil['tahun'].toString();
    _deskripsiController.text = widget.mobil['deskripsi'];
    _hargaController.text = widget.mobil['harga'].toString();
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
          print("DEBUG: URL BARU: $finalImageUrl");
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
      print("DEBUG ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aduh Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
