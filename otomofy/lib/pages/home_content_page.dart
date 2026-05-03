import 'package:flutter/material.dart';
import 'package:otomofy/pages/start_game_screen.dart';
import 'marketplace_page.dart';
import 'jual_page.dart';
import 'favorit_page.dart';
import 'cari_bengkel_page.dart';
import 'quiz_page.dart';

// =========================================================
// Metro Tile Home Content
// =========================================================
class HomeContentPage extends StatefulWidget {
  final int idUser;
  final String namaUser;
  // Callback to switch body in the parent shell (same as drawer nav)
  final void Function(Widget page, String title) onNavigate;

  const HomeContentPage({
    Key? key,
    required this.idUser,
    required this.namaUser,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage>
    with TickerProviderStateMixin {
  int? _pressedIndex;

  // Tracks whether tiles have played their entrance animation
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // ---- Tile definitions --------------------------------------------------
  late final List<_TileData> _tiles;

  @override
  void initState() {
    super.initState();

    _tiles = [
      // 0 – Marketplace (WIDE)
      _TileData(
        isWide: true,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.storefront_rounded,
        label: 'MARKETPLACE',
        tagline: 'Beli Mobil\nImpian Anda',
        subtext: '🚗  Ribuan pilihan · Harga terbaik',
        onTap: () => widget.onNavigate(
          MarketplacePage(userId: widget.idUser.toString()),
          'Bursa Mobil',
        ),
      ),
      // 1 – Jual Mobil (SMALL)
      _TileData(
        isWide: false,
        gradient: const LinearGradient(
          colors: [Color(0xFFE65C00), Color(0xFFF9D423)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.sell_rounded,
        label: 'JUAL MOBIL',
        tagline: 'Pasang\nIklan Gratis',
        subtext: '💰  Raih harga terbaik',
        onTap: () => widget.onNavigate(
          JualPage(userId: widget.idUser.toString()),
          'Jual Mobil',
        ),
      ),
      // 2 – Favorit (SMALL)
      _TileData(
        isWide: false,
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFFE040FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.favorite_rounded,
        label: 'FAVORIT',
        tagline: 'Simpan &\nTemukan Lagi',
        subtext: '❤️  Koleksi pilihan kamu',
        onTap: () => widget.onNavigate(
          FavoritPage(userId: widget.idUser.toString()),
          'Mobil Favorit',
        ),
      ),
      // 3 – Cari Bengkel (WIDE)
      _TileData(
        isWide: true,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D7C66), Color(0xFF1FAB89)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.build_circle_rounded,
        label: 'CARI BENGKEL',
        tagline: 'Bengkel Terpercaya\ndi Dekat Anda',
        subtext: '📍  GPS · Terdekat · Terpercaya',
        onTap: () => widget.onNavigate(
          const CariBengkelPage(),
          'Cari Bengkel',
        ),
      ),
      // 4 – Kuis Otomotif (SMALL)
      _TileData(
        isWide: false,
        gradient: const LinearGradient(
          colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.quiz_rounded,
        label: 'KUIS OTOMOTIF',
        tagline: 'Uji\nPengetahuanmu',
        subtext: '🧠  Seberapa paham kamu?',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizScreen()),
          );
        },
      ),
      // 5 – Car Maze Mini Game (SMALL)
      _TileData(
        isWide: false,
        gradient: const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.sports_esports_rounded,
        label: 'CAR MAZE',
        tagline: 'Tantang\nReflexmu!',
        subtext: '🎮  Mini game seru',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      ),
    ];

    // Build staggered entrance animations
    _controllers = List.generate(
      _tiles.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );

    _fadeAnims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _slideAnims = _controllers.map((c) {
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
    }).toList();

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 80 + i * 90), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              children: [
                _animatedTile(_buildWideTile(_tiles[0], 0), 0),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _animatedTile(_buildSmallTile(_tiles[1], 1), 1)),
                    const SizedBox(width: 10),
                    Expanded(child: _animatedTile(_buildSmallTile(_tiles[2], 2), 2)),
                  ],
                ),
                const SizedBox(height: 10),
                _animatedTile(_buildWideTile(_tiles[3], 3), 3),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _animatedTile(_buildSmallTile(_tiles[4], 4), 4)),
                    const SizedBox(width: 10),
                    Expanded(child: _animatedTile(_buildSmallTile(_tiles[5], 5), 5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Header --------------------------------------------------------------
  Widget _buildGreetingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang,',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.namaUser,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Apa yang ingin kamu lakukan hari ini?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Entrance animation wrapper ------------------------------------------
  Widget _animatedTile(Widget child, int index) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  // ---- Wide tile -----------------------------------------------------------
  Widget _buildWideTile(_TileData tile, int index) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        tile.onTap();
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        scale: _pressedIndex == index ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 145,
          decoration: BoxDecoration(
            gradient: tile.gradient,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Watermark icon
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  tile.icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              // Top-right corner label badge
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tile.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tile.icon, color: Colors.white, size: 28),
                    const Spacer(),
                    Text(
                      tile.tagline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tile.subtext,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Small tile ----------------------------------------------------------
  Widget _buildSmallTile(_TileData tile, int index) {
    // The label strip at the bottom is ~28px tall; we reserve that space
    // so the content column never bleeds into it.
    const double _stripHeight = 28.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) {
        setState(() => _pressedIndex = null);
        tile.onTap();
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        scale: _pressedIndex == index ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: tile.gradient,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Watermark icon – shift up so it doesn't overlap the strip
              Positioned(
                right: -8,
                bottom: _stripHeight,
                child: Icon(
                  tile.icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
              // Bottom label strip (rendered first so content sits above it)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: _stripHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    tile.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Content – padded so it never touches the strip
              Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, _stripHeight + 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tile.icon, color: Colors.white, size: 24),
                    const Spacer(),
                    Text(
                      tile.tagline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tile.subtext,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Data model for a tile -----------------------------------------------
class _TileData {
  final bool isWide;
  final Gradient gradient;
  final IconData icon;
  final String label;
  final String tagline;
  final String subtext;
  final VoidCallback onTap;

  const _TileData({
    required this.isWide,
    required this.gradient,
    required this.icon,
    required this.label,
    required this.tagline,
    required this.subtext,
    required this.onTap,
  });
}
