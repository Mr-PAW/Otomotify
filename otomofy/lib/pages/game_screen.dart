import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/maze_model.dart';
import '../widgets/car_painter.dart';
import '../widgets/maze_painter.dart';
import '../database/database_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Car physics
  double carX = 0.4; // 0.0 - 1.0 relative
  double carY = 0.02; // 0.0 - 1.0 relative
  double velocityX = 0.0;
  double velocityY = 0.0;
  bool isOnPlatform = false;
  int currentPlatformIndex = -1; // which platform car is resting on

  static const double carWidth = 44.0;
  static const double carHeight = 60.0;
  static const double gravity = 0.0025; // per frame
  static const double tiltSensitivity = 0.004;
  static const double friction = 0.88;
  static const double maxVelocityX = 0.015;

  // Game state
  bool gameStarted = false;
  bool gameCompleted = false;
  bool isPaused = false;
  int elapsedMs = 0;
  Timer? gameTimer;
  Timer? physicsTimer;
  DateTime? startTime;
  StreamSubscription? _accelSubscription;

  // Tilt
  double tiltX = 0.0;

  // Animation
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Maze
  late List<MazePlatform> platforms;

  // Trail effect
  final List<Offset> carTrail = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    platforms = generateMaze();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startListeningToSensors();
  }

  void _startListeningToSensors() {
    _accelSubscription = accelerometerEventStream().listen((event) {
      if (gameStarted && !gameCompleted && !isPaused) {
        setState(() {
          // event.x: negative = tilt right, positive = tilt left
          tiltX = -event.x * tiltSensitivity;
        });
      }
    });
  }

  void _startGame() {
    setState(() {
      carX = 0.4;
      carY = 0.02;
      velocityX = 0.0;
      velocityY = 0.0;
      isOnPlatform = false;
      currentPlatformIndex = -1;
      gameStarted = true;
      gameCompleted = false;
      isPaused = false;
      elapsedMs = 0;
      carTrail.clear();
    });

    startTime = DateTime.now();
    gameTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (!isPaused && !gameCompleted) {
        setState(() {
          elapsedMs = DateTime.now().difference(startTime!).inMilliseconds;
        });
      }
    });

    physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePhysics();
    });
  }

  void _updatePhysics() {
    if (!gameStarted || gameCompleted || isPaused) return;

    setState(() {
      // Apply tilt to X velocity
      velocityX += tiltX;
      velocityX *= friction;
      velocityX = velocityX.clamp(-maxVelocityX, maxVelocityX);

      // Apply gravity to Y
      velocityY += gravity;

      // Tentative new position
      double newX = carX + velocityX;
      double newY = carY + velocityY;

      // Wall collision
      final maxCarX = 1.0 - (carWidth / _screenWidth());
      if (newX < 0) {
        newX = 0;
        velocityX = -velocityX * 0.4;
      }
      if (newX > maxCarX) {
        newX = maxCarX;
        velocityX = -velocityX * 0.4;
      }

      // Check platform collision
      isOnPlatform = false;
      for (int i = 0; i < platforms.length; i++) {
        final platform = platforms[i];
        final size = Size(_screenWidth(), _screenHeight());
        final carRect = Rect.fromLTWH(
          newX * size.width,
          newY * size.height,
          carWidth,
          carHeight,
        );

        // Only collide from above (car falling down)
        final oldCarBottom = (carY * size.height) + carHeight;
        final platformTop = platform.yPercent * size.height;

        if (oldCarBottom <= platformTop + 2 &&
            carRect.bottom >= platformTop &&
            platform.collidesWithCar(carRect, size)) {
          // Car landed on this platform
          newY = (platformTop - carHeight) / size.height;
          velocityY = 0;
          isOnPlatform = true;
          currentPlatformIndex = i;
          _shakeController.forward(from: 0);
          break;
        }
      }

      // Trail
      carTrail.add(
        Offset(
          (newX + 0.5 * carWidth / _screenWidth()) * _screenWidth(),
          newY * _screenHeight(),
        ),
      );
      if (carTrail.length > 20) carTrail.removeAt(0);

      carX = newX;
      carY = newY;

      // Check completion - car reached bottom
      if (newY * _screenHeight() + carHeight >= _screenHeight() - 25) {
        _onGameComplete();
      }
    });
  }

  double _screenWidth() {
    return MediaQuery.of(context).size.width;
  }

  double _screenHeight() {
    return MediaQuery.of(context).size.height;
  }

  void _onGameComplete() {
    gameCompleted = true;
    gameTimer?.cancel();
    physicsTimer?.cancel();
    _pulseController.stop();
    DatabaseService().insertRecord(elapsedMs);

    Future.delayed(const Duration(milliseconds: 500), () {
      _showCompleteDialog();
    });
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🏁 FINISH!',
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            color: const Color(0xFFCE93D8),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waktu kamu:',
              style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(elapsedMs),
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00E5FF),
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // return to home
              },
              child: Text(
                'Kembali ke Menu',
                style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog() {
    setState(() => isPaused = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar Game?',
          style: GoogleFonts.orbitron(
            color: const Color(0xFFCE93D8),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Progress kamu akan hilang. Yakin ingin keluar?',
          style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => isPaused = false);
            },
            child: Text(
              'Lanjut Main',
              style: GoogleFonts.rajdhani(
                color: const Color(0xFFCE93D8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              gameTimer?.cancel();
              physicsTimer?.cancel();
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final centiseconds = (ms % 1000) ~/ 10;
    return '${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}s';
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    gameTimer?.cancel();
    physicsTimer?.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        if (gameStarted && !gameCompleted) {
          _showQuitDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D001A),
        body: Stack(
          children: [
            // Maze area
            if (gameStarted)
              Positioned.fill(
                child: CustomPaint(painter: MazePainter(platforms: platforms)),
              ),

            // Car trail
            if (gameStarted)
              Positioned.fill(
                child: CustomPaint(painter: _TrailPainter(trail: carTrail)),
              ),

            // Car
            if (gameStarted)
              Positioned(
                left: carX * size.width,
                top: carY * size.height,
                width: carWidth,
                height: carHeight,
                child: CustomPaint(
                  painter: CarPainter(
                    bodyColor: isOnPlatform
                        ? const Color(0xFFAB47BC)
                        : const Color(0xFF9C27B0),
                  ),
                ),
              ),

            // HUD - Timer
            if (gameStarted)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7B1FA2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer,
                        color: Color(0xFFCE93D8),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(elapsedMs),
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // QUIT button
            if (gameStarted)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: GestureDetector(
                  onTap: _showQuitDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B1FA2).withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'QUIT',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Progress indicator (which platform)
            if (gameStarted)
              Positioned(
                right: 8,
                top: size.height * 0.2,
                bottom: size.height * 0.1,
                child: _buildProgressBar(),
              ),

            // Start screen overlay
            if (!gameStarted) Positioned.fill(child: _buildStartOverlay(size)),

            // Pause overlay
            if (isPaused)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Text(
                      'PAUSED',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalPlatforms = platforms.length;
    final passed = currentPlatformIndex + 1;
    return Column(
      children: [
        Text(
          '${passed}/${totalPlatforms}',
          style: GoogleFonts.orbitron(
            color: const Color(0xFFCE93D8),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withOpacity(0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  heightFactor: passed / (totalPlatforms + 1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF00E5FF), Color(0xFF7B1FA2)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Icon(Icons.flag, color: Color(0xFF00E5FF), size: 14),
      ],
    );
  }

  Widget _buildStartOverlay(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF2D0050), Color(0xFF0D001A)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Car preview
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: SizedBox(
                width: 80,
                height: 110,
                child: CustomPaint(painter: CarPainter()),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'CAR MAZE',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFCE93D8),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [
                Shadow(
                  color: const Color(0xFF7B1FA2).withOpacity(0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TILT untuk bergerak • Lewati celah untuk turun',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              color: Colors.white54,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _startGame,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF4A148C)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                'MULAI',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '← Kembali',
              style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> trail;

  _TrailPainter({required this.trail});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 1; i < trail.length; i++) {
      final opacity = i / trail.length;
      final paint = Paint()
        ..color = const Color(0xFF9C27B0).withOpacity(opacity * 0.4)
        ..strokeWidth = 3 * opacity
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(trail[i - 1], trail[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) => true;
}
