# Fitur Biometric Login - Otomotify

Dokumentasi lengkap tentang implementasi fitur login menggunakan biometric (sidik jari) di aplikasi Otomotify.

## 📱 Overview

Fitur biometric login memungkinkan pengguna untuk login ke aplikasi Otomotify menggunakan sidik jari (fingerprint) mereka, tanpa perlu memasukkan username dan password setiap kali.

## 🎯 Keunggulan

- **Kemudahan**: Login hanya dengan sidik jari, lebih cepat dari memasukkan username dan password
- **Keamanan**: Menggunakan mekanisme keamanan native device (Android/iOS)
- **Seamless**: Terintegrasi dengan login form yang sudah ada
- **Smart**: Menyimpan user terakhir yang login, untuk kemudahan login berikutnya

## 🛠 File-file yang Ditambahkan

### 1. **lib/services/biometric_service.dart**
Service untuk menangani semua operasi biometric authentication.

```dart
class BiometricService {
  // Cek apakah device support biometric
  Future<bool> canCheckBiometrics()
  
  // Cek apakah device memiliki biometric yang terdaftar
  Future<bool> isDeviceSupported()
  
  // Dapatkan list biometric yang tersedia
  Future<List<BiometricType>> getAvailableBiometrics()
  
  // Autentikasi menggunakan biometric
  Future<bool> authenticate()
  
  // Stop/berhentikan proses autentikasi
  Future<void> stopAuthentication()
}
```

### 2. **lib/services/biometric_preferences_service.dart**
Service untuk menyimpan preferensi biometric user di local storage.

```dart
class BiometricPreferencesService {
  // Simpan username user terakhir yang login dengan biometric
  Future<void> setLastBiometricUser(String username)
  
  // Ambil username user terakhir
  Future<String?> getLastBiometricUser()
  
  // Hapus data user terakhir (logout)
  Future<void> clearLastBiometricUser()
  
  // Enable/disable biometric untuk user tertentu
  Future<void> enableBiometricForUser(String username)
  Future<void> disableBiometricForUser(String username)
}
```

### 3. **lib/pages/login_page.dart** (Updated)
Login page sudah diupdate dengan:
- Import biometric services
- State variables untuk biometric
- Method `_doBiometricLogin()` untuk proses login biometric
- Button "LOGIN DENGAN SIDIK JARI" di UI

## 📦 Dependencies yang Ditambahkan

Di `pubspec.yaml`:

```yaml
dependencies:
  local_auth: ^2.3.0          # Biometric authentication
  shared_preferences: ^2.2.3  # Local storage untuk preferences
```

## 🔧 Konfigurasi Android

### AndroidManifest.xml (android/app/src/main/AndroidManifest.xml)

Sudah ditambahkan permissions:

```xml
<!-- Permissions untuk Biometric Authentication (Fingerprint) -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### Build Configuration (Jika diperlukan)

Untuk Android versi 28+, biometric sudah didukung out-of-the-box.

## 🚀 Cara Menggunakan

### 1. **Login dengan Username dan Password**

```
1. User memasukkan username dan password
2. Click tombol "LOGIN"
3. Jika benar, akan login dan username disimpan untuk biometric login
4. User akan di-redirect ke HomePage
```

### 2. **Login dengan Biometric (Login Berikutnya)**

```
1. Di halaman login, akan muncul button "LOGIN DENGAN SIDIK JARI"
   (hanya jika device support biometric)
2. Click button tersebut
3. Tempatkan jari di sensor biometric device
4. Jika berhasil dikenali, user akan login dengan username yang disimpan sebelumnya
5. User akan di-redirect ke HomePage
```

## 💡 Alur Kerja

### Flow 1: Login Pertama (Username & Password)
```
┌─────────────────────┐
│  Login Page         │
│  - Username input   │
│  - Password input   │
│  - Login button     │
└──────────┬──────────┘
           │
           ↓
    ┌──────────────────┐
    │ Verify Username  │
    │ & Password       │
    └────────┬─────────┘
             │
       ┌─────┴─────┐
       │ Valid?    │
       └─┬─────────┘
         │
    ┌────┴────┐
    │   YES   │ NO
    │         │
    ↓         ↓
[Success] [Show Error]
    │
    ├─ Save username to SharedPreferences
    ├─ Navigate to HomePage
    │
    └─→ Biometric button akan muncul di login page berikutnya
```

### Flow 2: Login Biometric (Kali Berikutnya)
```
┌──────────────────────────┐
│  Login Page              │
│  - Username input        │
│  - Password input        │
│  - Login button          │
│  - LOGIN DENGAN SIDIK JARI   (NEW!)
└────────────┬─────────────┘
             │
             ↓
   ┌────────────────────┐
   │ Click Biometric    │
   │ Button             │
   └────────┬───────────┘
            │
            ↓
   ┌────────────────────────┐
   │ Device meminta sidik   │
   │ jari dari user         │
   └────────┬───────────────┘
            │
        ┌───┴───┐
        │       │
      YES      NO
        │       │
        ↓       ↓
    [Success] [Failed]
        │       │
        ├───┬───┤
            │
    ┌───────┴───────┐
    │ Get saved     │
    │ username from │
    │ SharedPrefs   │
    └───────┬───────┘
            │
            ↓
    ┌───────────────────┐
    │ Find user in      │
    │ dummyUsers list   │
    └───────┬───────────┘
            │
            ↓
    ┌───────────────────┐
    │ Navigate to       │
    │ HomePage          │
    └───────────────────┘
```

## 📋 Syarat & Ketentuan Penggunaan Biometric

1. **Device Requirements**:
   - Device harus support biometric authentication
   - Minimal 1 fingerprint harus terdaftar di device

2. **Behavior**:
   - Jika user belum login dengan username/password, biometric button tidak akan berfungsi
   - Setelah logout, saved username akan tetap tersimpan
   - User bisa logout dan login dengan user yang berbeda

3. **Security**:
   - Username disimpan di `SharedPreferences` (local device storage)
   - Password tidak pernah disimpan
   - Biometric authentication menggunakan secure enclave di device

## 🧪 Testing

### Test Case 1: Check Biometric Availability
```dart
final service = BiometricService();
bool isAvailable = await service.isDeviceSupported();
print('Biometric available: $isAvailable');
```

### Test Case 2: Authenticate
```dart
final service = BiometricService();
bool success = await service.authenticate();
print('Authentication: $success');
```

### Test Case 3: Save Last User
```dart
final prefs = BiometricPreferencesService();
await prefs.setLastBiometricUser('dito');

final lastUser = await prefs.getLastBiometricUser();
print('Last user: $lastUser'); // Output: dito
```

## ⚠️ Known Limitations & Future Improvements

### Current Limitations:
1. Hanya support 1 user (user terakhir yang login)
2. Tidak ada option untuk "disable biometric" per user
3. Username disimpan di local storage (bisa dilihat di debug mode)

### Future Improvements:
1. Support multiple users dengan biometric
2. Add "Remember this device" option
3. Enkripsi username yang disimpan
4. Face recognition (face unlock) untuk iOS
5. Biometric settings page untuk user management

## 🐛 Troubleshooting

### Issue: Biometric button tidak muncul
**Solution**: 
- Pastikan device support biometric (cek di Android Settings → Security)
- Pastikan minimal 1 fingerprint sudah terdaftar
- Restart aplikasi

### Issue: "Autentikasi biometric gagal"
**Solution**:
- Check sensor biometric (bersihkan jari)
- Pastikan sudah terdaftar di device
- Coba login dengan username/password terlebih dahulu

### Issue: "User tidak ditemukan"
**Solution**:
- Hapus app cache: Settings → Apps → otomofy → Storage → Clear Cache
- Logout dan login ulang dengan username/password yang benar

## 📞 Support

Untuk pertanyaan atau issues, hubungi tim development Otomotify.

---

**Last Updated**: May 3, 2026  
**Version**: 1.0
