import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TimePage extends StatefulWidget {
  const TimePage({Key? key}) : super(key: key);

  @override
  State<TimePage> createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  late Timer _timer;
  late DateTime _currentTime;
  String _selectedZone = 'WIB';

  // Map zona waktu ke offset jam dari UTC
  final Map<String, int> _zoneOffsets = {
    'London (GMT)': 0,
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
  };

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Update setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Mengambil waktu berdasarkan zona yang dipilih
  DateTime _getConvertedTime() {
    // Ambil waktu UTC
    DateTime utcTime = _currentTime.toUtc();
    // Tambahkan offset
    return utcTime.add(Duration(hours: _zoneOffsets[_selectedZone]!));
  }

  @override
  Widget build(BuildContext context) {
    DateTime displayedTime = _getConvertedTime();
    String formattedTime = DateFormat('HH:mm:ss').format(displayedTime);
    String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(displayedTime);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text('Konversi Waktu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'Zona Waktu: $_selectedZone',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Main Clock
            Text(
              formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w300,
                fontFamily: 'Courier', // Gaya digital retro
                letterSpacing: 4,
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 80),

            // Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _zoneOffsets.keys.map((zone) {
                  bool isSelected = _selectedZone == zone;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedZone = zone),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyanAccent : Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        zone,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              'Waktu dihitung berdasarkan UTC (Universal Time)',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
