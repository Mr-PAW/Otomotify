import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

// Import local database helper
import '../services/profile_database.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfilePage({Key? key, required this.userId, required this.userName})
      : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();


  
  bool _isSaving = false;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _profilePictureLocalPath;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Load profile from local SQLite database
  Future<void> _fetchProfileData() async {
    if (_hasLoadedData) return;

    try {
      final profile = await ProfileDatabase.instance.getProfile(widget.userId);

      if (!mounted) return;

      if (profile != null) {
        setState(() {
          _nameController.text = profile['nama'] ?? widget.userName;
          _usernameController.text = profile['username'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          
          final picPath = profile['profile_picture'];
          if (picPath != null && picPath.toString().isNotEmpty) {
            _profilePictureLocalPath = picPath;
            _imageFile = File(picPath);
          }
          _hasLoadedData = true;
        });
      } else {
        // If no profile in DB, use widget parameters
        setState(() {
          _nameController.text = widget.userName;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      debugPrint('Fetch profil error: $e');
      if (mounted) setState(() => _hasLoadedData = true);
    }
  }

  // Save profile to local SQLite database
  Future<void> _updateProfileData() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final profile = {
        'userId': widget.userId,
        'nama': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_picture': _profilePictureLocalPath ?? '',
      };

      await ProfileDatabase.instance.saveProfile(profile);

      if (!mounted) return;
      _showSnack('Profil berhasil disimpan', Colors.green);
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan profil: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Pick an image, copy it to the app's local directory, and save the path to SQLite
  Future<void> _pickAndUploadImage() async {
    debugPrint('=== CAMERA BUTTON TAPPED ===');
    if (_isUploading) {
      debugPrint('Already uploading, returning.');
      return;
    }

    try {
      debugPrint('Opening image picker...');
      _showSnack('Membuka galeri...', Colors.blue);
      
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      debugPrint('Image picker returned. pickedFile: \${pickedFile?.path}');
      if (pickedFile == null || !mounted) return;

      setState(() => _isUploading = true);

      // Copy the picked image to the app's permanent document directory
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(pickedFile.path);
      // Ensure unique filename by prepending timestamp
      final String uniqueFileName = '\${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final String savedPath = path.join(directory.path, uniqueFileName);
      
      final File newImage = await File(pickedFile.path).copy(savedPath);

      // Save to SQLite
      final profile = {
        'userId': widget.userId,
        'nama': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_picture': newImage.path,
      };
      
      await ProfileDatabase.instance.saveProfile(profile);

      // Also delete the old photo from disk if there was one to save space
      if (_profilePictureLocalPath != null) {
        final oldFile = File(_profilePictureLocalPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      if (!mounted) return;

      setState(() {
        _profilePictureLocalPath = newImage.path;
        _imageFile = newImage;
      });
      _showSnack('Foto profil berhasil diperbarui', Colors.green);
      
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        _showSnack('Gagal memilih foto.', Colors.orange);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  ImageProvider? get _avatarImage {
    if (_imageFile != null && _imageFile!.existsSync()) {
      return FileImage(_imageFile!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: !_hasLoadedData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header dengan avatar ──
                  SizedBox(
                    height: 240, // 180 (header) + 60 (setengah avatar)
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: const SafeArea(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Profil Saya',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 120, // 180 - 60 (radius) = 120
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  child: _isUploading
                                      ? const CircularProgressIndicator()
                                      : CircleAvatar(
                                          radius: 56,
                                          backgroundColor: Colors.grey[300],
                                          backgroundImage: _avatarImage,
                                          child: _avatarImage == null
                                              ? Icon(Icons.person,
                                                  size: 60, color: Colors.grey[600])
                                              : null,
                                        ),
                                ),
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFF7B1FA2),
                                  child: Icon(Icons.camera_alt,
                                      size: 20, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced from 65 since the avatar is now fully inside the 240 height

                  // ── Form ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nama Lengkap',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Nomor Telepon',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),

                        // Tombol Simpan
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3C72),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    'SIMPAN PERUBAHAN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3C72)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3C72), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
