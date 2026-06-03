import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  /// Called when the user successfully saves profile changes so the parent
  /// (HomePage) can refresh the drawer name / picture.
  final void Function(String newName, String? newPicPath)? onProfileUpdated;

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.userName,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────────
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _isUploadingPic = false;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  File? _imageFile;
  String? _profilePicPath;

  final ImagePicker _picker = ImagePicker();
  static const int _maxFileSizeBytes = 500 * 1024; // 500 KB

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ── Example user detection ─────────────────────────────────────────────────
  /// Example users have negative IDs (e.g. -1, -2, -3).
  /// They are fully offline and cannot update profile data.
  bool get _isExampleUser {
    final id = int.tryParse(widget.userId);
    return id != null && id < 0;
  }

  // ── Load current user from backend ──────────────────────────────────────────
  Future<void> _loadProfile() async {
    // Example users don't have a backend account — just use the widget params
    if (_isExampleUser) {
      setState(() {
        _nameController.text = widget.userName;
        _emailController.text = 'demo@example.local';
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final user = await AuthService.getMe();
      final picPath = await ProfileService.getProfilePicPath(widget.userId);

      if (!mounted) return;
      setState(() {
        if (user != null) {
          _nameController.text = user.name;
          _emailController.text = user.email;
        } else {
          _nameController.text = widget.userName;
        }
        _profilePicPath = picPath;
        _imageFile = picPath != null ? File(picPath) : null;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        _showSnack('Gagal memuat profil: $e', Colors.orange);
      }
    }
  }

  // ── Pick & save profile picture ─────────────────────────────────────────────
  Future<void> _pickProfilePicture() async {
    if (_isUploadingPic) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    // ── 500 KB size check ────────────────────────────────────────────────────
    final fileSize = await File(picked.path).length();
    if (fileSize > _maxFileSizeBytes) {
      _showSnack(
        'Ukuran foto maksimal 500 KB. Foto ini ${(fileSize / 1024).toStringAsFixed(0)} KB.',
        Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() => _isUploadingPic = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
      final savedPath = path.join(dir.path, uniqueName);
      final newFile = await File(picked.path).copy(savedPath);

      // Delete old file to save space
      if (_profilePicPath != null) {
        final old = File(_profilePicPath!);
        if (await old.exists()) await old.delete();
      }

      await ProfileService.saveProfilePicPath(widget.userId, newFile.path);

      if (!mounted) return;
      setState(() {
        _profilePicPath = newFile.path;
        _imageFile = newFile;
      });

      widget.onProfileUpdated?.call(_nameController.text.trim(), newFile.path);
      _showSnack('Foto profil berhasil diperbarui ✓', Colors.green);
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan foto: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUploadingPic = false);
    }
  }

  // ── Save name + email to backend ────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (_isExampleUser) return; // safety guard
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnack('Nama dan email tidak boleh kosong', Colors.orange);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnack('Format email tidak valid', Colors.orange);
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      final result = await AuthService.updateProfile(name: name, email: email);
      if (!mounted) return;

      if (result['success'] == true) {
        widget.onProfileUpdated?.call(name, _profilePicPath);
        _showSnack('Profil berhasil disimpan ✓', Colors.green);
      } else {
        _showSnack(
          result['message'] ?? 'Gagal menyimpan profil',
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  // ── Change password ──────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (_isExampleUser) return; // safety guard
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack('Semua field password wajib diisi', Colors.orange);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Password baru minimal 6 karakter', Colors.orange);
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Konfirmasi password tidak cocok', Colors.orange);
      return;
    }

    setState(() => _isSavingPassword = true);
    try {
      final result = await AuthService.changePassword(
        oldPassword: oldPass,
        newPassword: newPass,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        _showSnack('Password berhasil diubah ✓', Colors.green);
      } else {
        _showSnack(
          result['message'] ?? 'Gagal mengubah password',
          Colors.redAccent,
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  void _showSnack(
    String msg,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  ImageProvider? get _avatar {
    if (_imageFile != null && _imageFile!.existsSync()) {
      return FileImage(_imageFile!);
    }
    return null;
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile Picture Section ─────────────────────────────────────────
          _buildPictureSection(),

          // ── Example user notice ─────────────────────────────────────────────
          if (_isExampleUser)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Akun contoh — perbarui profil & ubah password tidak tersedia. '
                      'Daftar atau login dengan akun nyata untuk menggunakan fitur ini.',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),

          // ── Informasi Akun Card ─────────────────────────────────────────────
          _buildSectionCard(
            title: 'Informasi Akun',
            icon: Icons.person_outline,
            child: Column(
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Nama / Username',
                  icon: Icons.badge_outlined,
                  readOnly: _isExampleUser,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  readOnly: _isExampleUser,
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: 'SIMPAN PERUBAHAN',
                  isLoading: _isSavingProfile,
                  onPressed: _saveProfile,
                  disabled: _isExampleUser,
                  color: const Color.fromARGB(255, 60, 244, 4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Ubah Password Card ──────────────────────────────────────────────
          _buildSectionCard(
            title: 'Ubah Password',
            icon: Icons.lock_outline,
            child: Column(
              children: [
                _buildField(
                  controller: _oldPassController,
                  label: 'Password Lama',
                  icon: Icons.lock_open_outlined,
                  obscure: _obscureOld,
                  toggleObscure: () =>
                      setState(() => _obscureOld = !_obscureOld),
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _newPassController,
                  label: 'Password Baru',
                  icon: Icons.lock_reset_outlined,
                  obscure: _obscureNew,
                  toggleObscure: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _confirmPassController,
                  label: 'Konfirmasi Password Baru',
                  icon: Icons.lock_outlined,
                  obscure: _obscureConfirm,
                  toggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 20),
                _buildPrimaryButton(
                  label: 'UBAH PASSWORD',
                  isLoading: _isSavingPassword,
                  onPressed: _changePassword,
                  color: const Color(0xFF7B1FA2),
                  disabled: _isExampleUser,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildPictureSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 246, 2, 2), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploadingPic ? null : _pickProfilePicture,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white24,
                  backgroundImage: _avatar,
                  child: _avatar == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white70,
                        )
                      : null,
                ),
                if (_isUploadingPic)
                  const Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF7B1FA2),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nameController.text.isNotEmpty
                ? _nameController.text
                : widget.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap foto untuk ganti · Maks. 500 KB',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF1E3C72), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool? obscure,
    VoidCallback? toggleObscure,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure ?? false,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: readOnly
              ? const Color.fromARGB(255, 255, 0, 0)
              : const Color(0xFF1E3C72),
        ),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  (obscure ?? false) ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey[200]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey[300]! : const Color(0xFF1E3C72),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color color = const Color(0xFF1E3C72),
    bool disabled = false,
  }) {
    final isDisabled = isLoading || disabled;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey[300] : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: disabled ? 0 : 3,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: disabled ? Colors.grey[500] : Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
