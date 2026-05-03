import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/bengkel_model.dart';

class CariBengkelPage extends StatefulWidget {
  const CariBengkelPage({super.key});

  @override
  State<CariBengkelPage> createState() => _CariBengkelPageState();
}

class _CariBengkelPageState extends State<CariBengkelPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final Distance _distance = const Distance();

  LatLng? _centerMap;
  LatLng? _currentLocation;
  bool _loadingLocation = true;
  String _query = '';
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError =
              'Layanan lokasi tidak aktif. Silakan aktifkan di pengaturan HP.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError =
              'Izin lokasi ditolak. Silakan berikan izin di pengaturan HP.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _centerMap = location;
        _loadingLocation = false;
        _locationError = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError =
            'Gagal mendapatkan lokasi: ${e.toString().substring(0, 50)}...';
      });
    }
  }

  double _distanceKm(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Kilometer, a, b);
  }

  List<BengkelModel> get _filteredBengkel {
    final keyword = _query.trim().toLowerCase();

    final filtered = dummyBengkelJogja.where((bengkel) {
      if (keyword.isEmpty) return true;
      return bengkel.nama.toLowerCase().contains(keyword) ||
          bengkel.alamat.toLowerCase().contains(keyword) ||
          bengkel.kecamatan.toLowerCase().contains(keyword) ||
          bengkel.kabupaten.toLowerCase().contains(keyword) ||
          bengkel.layanan.any((item) => item.toLowerCase().contains(keyword));
    }).toList();

    if (_currentLocation != null) {
      filtered.sort((a, b) {
        final distanceA = _distanceKm(_currentLocation!, a.lokasi);
        final distanceB = _distanceKm(_currentLocation!, b.lokasi);
        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _filteredBengkel.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Bengkel'),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari bengkel, kecamatan, atau layanan...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadingLocation
                            ? 'Mengambil lokasi HP Anda...'
                            : (_locationError.isNotEmpty
                                  ? _locationError
                                  : 'Lokasi HP aktif, rekomendasi diurutkan dari terdekat'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _getCurrentLocation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loadingLocation)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_centerMap == null)
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Lokasi tidak tersedia',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _locationError,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3C72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _centerMap!,
                          initialZoom: 13,
                          minZoom: 10,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'otomofy',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.blue,
                                    size: 44,
                                  ),
                                ),
                              ...dummyBengkelJogja.map(
                                (bengkel) => Marker(
                                  point: bengkel.lokasi,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.build_circle,
                                    color: Colors.redAccent,
                                    size: 34,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rekomendasi Bengkel Terdekat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${nearby.length} hasil',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingLocation)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (nearby.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Tidak ada bengkel yang cocok dengan pencarian Anda.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...nearby.map((bengkel) {
                      final distance = _currentLocation != null
                          ? _distanceKm(_currentLocation!, bengkel.lokasi)
                          : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(14),
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF1E3C72,
                            ).withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.build,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          title: Text(
                            bengkel.nama,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${bengkel.alamat}, ${bengkel.kecamatan}, ${bengkel.kabupaten}\n'
                              'Layanan: ${bengkel.layanan.join(', ')}\n'
                              '${_currentLocation != null ? 'Jarak: ${distance.toStringAsFixed(2)} km' : 'Telepon: ${bengkel.telepon}'}',
                              style: TextStyle(
                                height: 1.4,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.directions,
                                color: Color(0xFF1E3C72),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buka',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
