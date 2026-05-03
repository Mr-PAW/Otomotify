import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_service.dart';
import '../widgets/car_painter.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<GameRecord> records = [];
  GameRecord? bestRecord;
  bool isLoading = true;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _carController;
  late Animation<double> _carAnimation;

  @override
  void initState() {
    super.initState();
    _loadRecords();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _carAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  Future<void> _loadRecords() async {
    setState(() => isLoading = true);
    records = await DatabaseService().getRecords();
    bestRecord = await DatabaseService().getBestRecord();
    setState(() => isLoading = false);
  }

  Future<void> _startGame() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GameScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (result == true || result == null) {
      _loadRecords();
      _cardController.reset();
      Future.delayed(const Duration(milliseconds: 100), () {
        _cardController.forward();
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus History?',
          style: GoogleFonts.orbitron(color: const Color(0xFFCE93D8)),
        ),
        content: Text(
          'Semua riwayat waktu akan dihapus permanen.',
          style: GoogleFonts.rajdhani(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.rajdhani(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.rajdhani(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().clearRecords();
      _loadRecords();
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D001A),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) {
          return Stack(
            children: [
              // Animated background
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundPainter(progress: _bgController.value),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Header / Car animation
                    SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9C27B0,
                                  ).withOpacity(0.25),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          // Car
                          AnimatedBuilder(
                            animation: _carAnimation,
                            builder: (_, __) => Transform.translate(
                              offset: Offset(_carAnimation.value, 0),
                              child: const SizedBox(
                                width: 80,
                                height: 110,
                                child: CustomPaint(painter: CarPainter()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Text(
                      'CAR MAZE',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFCE93D8),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.7),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MINI GAME',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFF7B1FA2),
                        fontSize: 14,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Best time card
                    if (bestRecord != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00E5FF).withOpacity(0.15),
                                const Color(0xFF7B1FA2).withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Best: ',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white60,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                bestRecord!.formattedTime,
                                style: GoogleFonts.orbitron(
                                  color: const Color(0xFF00E5FF),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Start button
                    GestureDetector(
                      onTap: _startGame,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 48),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFAB47BC), Color(0xFF4A148C)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withOpacity(0.6),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MULAI BERMAIN',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // History section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RIWAYAT WAKTU',
                                  style: GoogleFonts.orbitron(
                                    color: const Color(0xFFCE93D8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                if (records.isNotEmpty)
                                  GestureDetector(
                                    onTap: _clearHistory,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(
                                            0xFF7B1FA2,
                                          ).withOpacity(0.6),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Hapus',
                                        style: GoogleFonts.rajdhani(
                                          color: Colors.white38,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF7B1FA2),
                                      ),
                                    )
                                  : records.isEmpty
                                  ? _buildEmptyHistory()
                                  : ScaleTransition(
                                      scale: _cardAnimation,
                                      child: ListView.separated(
                                        itemCount: records.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (_, i) =>
                                            _buildRecordTile(records[i], i),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 40, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 16),
          ),
          Text(
            'Selesaikan game untuk melihat waktu kamu!',
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(GameRecord record, int index) {
    final isBest = index == 0;
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBest
              ? [
                  const Color(0xFF7B1FA2).withOpacity(0.3),
                  const Color(0xFF4A148C).withOpacity(0.2),
                ]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBest
              ? const Color(0xFFCE93D8).withOpacity(0.5)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              index < 3 ? medals[index] : '#${index + 1}',
              style: TextStyle(
                fontSize: index < 3 ? 20 : 14,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time
          Expanded(
            child: Text(
              record.formattedTime,
              style: GoogleFonts.orbitron(
                color: isBest ? const Color(0xFF00E5FF) : Colors.white70,
                fontSize: 18,
                fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Date
          Text(
            _formatDate(record.completedAt),
            style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle moving particles / grid
    final paint = Paint()
      ..color = const Color(0xFF7B1FA2).withOpacity(0.06)
      ..strokeWidth = 1;

    final offset = progress * 30;
    for (double y = -30 + offset % 30; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Glowing orbs
    final orbPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    orbPaint.color = const Color(
      0xFF7B1FA2,
    ).withOpacity(0.12 + 0.05 * _sin(progress));
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      120,
      orbPaint,
    );

    orbPaint.color = const Color(
      0xFF4A148C,
    ).withOpacity(0.10 + 0.05 * _sin(progress + 0.3));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.6),
      100,
      orbPaint,
    );
  }

  double _sin(double t) => (1 + (t * 2 * 3.14159).abs() % 6.28319 < 3.14159
      ? 2 * (t * 2 * 3.14159).abs() % 6.28319 / 3.14159 - 1
      : 1 - 2 * ((t * 2 * 3.14159).abs() % 6.28319 - 3.14159) / 3.14159);

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
