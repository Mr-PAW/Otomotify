import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

class QiblaPage extends StatefulWidget {
  const QiblaPage({Key? key}) : super(key: key);

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  bool _hasPermissions = false;
  double? _qiblaDirection; // Arah Kiblat dari Utara Sejati (True North)
  Position? _currentPosition;

  // Koordinat Ka'bah (Makkah)
  final double meccaLat = 21.422487;
  final double meccaLon = 39.826206;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndQibla();
  }

  Future<void> _fetchLocationAndQibla() async {
    // Meminta izin lokasi
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => _hasPermissions = true);
      
      try {
        // Ambil lokasi saat ini
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
        setState(() {
          _currentPosition = position;
          _qiblaDirection = _calculateQibla(position.latitude, position.longitude);
        });
      } catch (e) {
        debugPrint("Error mendapatkan lokasi: $e");
      }
    } else {
      // Tampilkan error jika izin ditolak
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi diperlukan untuk menghitung arah Kiblat.')),
        );
      }
    }
  }

  double _calculateQibla(double lat, double lon) {
    // Rumus Trigonometri Bola untuk menghitung Arah Kiblat
    final double latRad = lat * math.pi / 180.0;
    final double lonRad = lon * math.pi / 180.0;
    final double meccaLatRad = meccaLat * math.pi / 180.0;
    final double meccaLonRad = meccaLon * math.pi / 180.0;

    final double y = math.sin(meccaLonRad - lonRad);
    final double x = math.cos(latRad) * math.tan(meccaLatRad) -
        math.sin(latRad) * math.cos(meccaLonRad - lonRad);

    double qibla = math.atan2(y, x) * 180.0 / math.pi;
    return (qibla + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72),
      appBar: AppBar(
        title: const Text('Kompas Kiblat', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !_hasPermissions
          ? _buildPermissionRequest()
          : _qiblaDirection == null
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildCompass(),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Akses Lokasi Diperlukan',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami butuh lokasi Anda untuk menghitung\narah Kiblat yang akurat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
            },
            child: const Text('Buka Pengaturan Lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Sensor Kompas Error', style: TextStyle(color: Colors.white)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        double? direction = snapshot.data?.heading; // Arah HP dari utara
        
        if (direction == null) {
          return const Center(
            child: Text(
              "Sensor kompas tidak ditemukan di perangkat ini.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        // Hitung selisih antara arah HP dan arah kiblat
        // Jika HP menghadap utara (0), jarum kiblat harus menunjuk ke _qiblaDirection
        // Karena lingkaran berputar ke arah sebaliknya saat HP diputar, 
        // kita menggunakan rotasi: (Qibla - HP)
        double qiblaAngle = (_qiblaDirection! - direction);
        double qiblaAngleRad = qiblaAngle * (math.pi / 180);
        
        // Jarum Utara juga perlu diputar kebalikan dari arah HP
        double northAngleRad = -direction * (math.pi / 180);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Arah Kiblat',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${_qiblaDirection!.toStringAsFixed(1)}° dari Utara',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 60),
              
              // Tampilan Kompas
              Stack(
                alignment: Alignment.center,
                children: [
                  // Latar Belakang Kompas
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                  ),
                  
                  // Titik-titik derajat pinggiran
                  for (int i = 0; i < 360; i += 15)
                    Transform.rotate(
                      angle: i * math.pi / 180,
                      child: Container(
                        width: 300,
                        height: 300,
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: i % 90 == 0 ? 4 : 2,
                          height: i % 90 == 0 ? 15 : 8,
                          color: i == 0 ? Colors.red : Colors.white54,
                        ),
                      ),
                    ),

                  // Jarum Utara (Merah/Putih)
                  Transform.rotate(
                    angle: northAngleRad,
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 40,
                            child: Column(
                              children: [
                                const Text('U', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                                const SizedBox(height: 5),
                                Icon(Icons.arrow_upward, color: Colors.red.withOpacity(0.5), size: 40),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            child: const Text('S', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          Positioned(
                            right: 40,
                            child: const Text('T', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          Positioned(
                            left: 40,
                            child: const Text('B', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Jarum Kiblat Utama (Ka'bah)
                  Transform.rotate(
                    angle: qiblaAngleRad,
                    child: Container(
                      width: 300,
                      height: 300,
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mosque, color: Colors.greenAccent, size: 60),
                            Container(
                              width: 4,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Titik Pusat
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Derajat HP saat ini
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Heading: ${direction.toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
