import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../models/obstacle_model.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController gc;
  Offset? _swipeStart;
  bool _navigatingAway = false;

  @override
  void initState() {
    super.initState();
    gc = Get.find<GameController>();
    _navigatingAway = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      gc.setScreenSize(size.width, size.height);
      gc.startGame(); // startGame() already resets everything internally
    });
  }

  @override
  void dispose() {
    // If we leave mid-game (e.g. back button), pause cleanly
    if (gc.gameState.value == GameState.playing) {
      gc.pauseGame();
    }
    super.dispose();
  }

  void _handleSwipe(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx.abs() > dy.abs()) {
      if (dx > 20) gc.onSwipeRight();
      if (dx < -20) gc.onSwipeLeft();
    } else {
      if (dy < -20) gc.onSwipeUp();
      if (dy > 20) gc.onSwipeDown();
    }
  }

  void _navigateToGameOver() {
    if (_navigatingAway || !mounted) return;
    _navigatingAway = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameOverScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanStart: (d) => _swipeStart = d.localPosition,
        onPanUpdate: (d) {
          if (_swipeStart != null) {
            final delta = d.localPosition - _swipeStart!;
            if (delta.distance > 30) {
              _handleSwipe(_swipeStart!, d.localPosition);
              _swipeStart = d.localPosition;
            }
          }
        },
        onPanEnd: (_) => _swipeStart = null,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B4B), Color(0xFF1A0533)],
            ),
          ),
          child: Stack(
            children: [
              // ── Track ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: GameController.trackWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // ── Obstacles ──────────────────────────────────────────
              Obx(() => Stack(
                children: gc.obstacles
                    .map((obs) => _ObstacleWidget(obstacle: obs))
                    .toList(),
              )),

              // ── Jelly ──────────────────────────────────────────────
              Obx(() {
                final j = gc.jelly.value;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  left: j.x - j.width / 2,
                  top: j.y - j.height / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: j.width,
                    height: j.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(j.width / 2),
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFB3D1), Color(0xFFFF6B9D)],
                        center: Alignment(-0.3, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('😊', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }),

              // ── Score + Pause bar ───────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text(
                          '${gc.displayScore.value}',
                          style: GoogleFonts.fredoka(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        GestureDetector(
                          onTap: () {
                            gc.pauseGame();
                            _showPauseDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(Icons.pause_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Swipe hint (first 10 points) ───────────────────────
              Obx(() {
                if (gc.displayScore.value >= 10) return const SizedBox.shrink();
                return Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Icon(Icons.swipe, color: Colors.white38, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Swipe to reshape!',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white38),
                      ),
                    ],
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 600.ms)
                      .then()
                      .fadeOut(duration: 600.ms),
                );
              }),

              // ── Game-over listener ─────────────────────────────────
              Obx(() {
                if (gc.gameState.value == GameState.gameOver) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _navigateToGameOver();
                  });
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PauseDialog(gc: gc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Obstacle Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ObstacleWidget extends StatelessWidget {
  final ObstacleModel obstacle;
  const _ObstacleWidget({required this.obstacle});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    // Full-width wall with a gap cut out
    return Positioned(
      left: 0,
      top: 0,
      child: CustomPaint(
        size: Size(screenW, screenH),
        painter: _ObstaclePainter(obstacle: obstacle),
      ),
    );
  }
}

class _ObstaclePainter extends CustomPainter {
  final ObstacleModel obstacle;
  _ObstaclePainter({required this.obstacle});

  @override
  void paint(Canvas canvas, Size size) {
    // Wall is a thin vertical bar at obstacle.x
    const double wallW = 30;
    final double wallLeft = obstacle.x - wallW / 2;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6B9DFF).withOpacity(0.9),
          const Color(0xFF9D6BFF).withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(wallLeft, 0, wallW, size.height))
      ..style = PaintingStyle.fill;

    final double gapTop = obstacle.gapY;
    final double gapBottom = obstacle.gapY + obstacle.gapHeight;

    // Wall above gap
    if (gapTop > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wallLeft, 0, wallW, gapTop),
          const Radius.circular(6),
        ),
        paint,
      );
    }

    // Wall below gap
    if (gapBottom < size.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wallLeft, gapBottom, wallW, size.height - gapBottom),
          const Radius.circular(6),
        ),
        paint,
      );
    }

    // Gap glow outline
    final glowPaint = Paint()
      ..color = const Color(0xFF6BFFD8).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(wallLeft, gapTop, wallW, obstacle.gapHeight),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_ObstaclePainter old) => old.obstacle.x != obstacle.x;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pause Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _PauseDialog extends StatelessWidget {
  final GameController gc;
  const _PauseDialog({required this.gc});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Paused',
              style: GoogleFonts.fredoka(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            _dialogButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              color: const Color(0xFF6BFFD8),
              onTap: () {
                Navigator.pop(context);
                gc.resumeGame();
              },
            ),
            const SizedBox(height: 14),
            _dialogButton(
              label: 'Menu',
              icon: Icons.home_rounded,
              color: const Color(0xFFFF6B9D),
              onTap: () {
                gc.startGame(); // reset so next game starts clean
                Navigator.of(context)
                  ..pop()   // close dialog
                  ..pop();  // go back to menu
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .scale(
      duration: 400.ms,
      curve: Curves.elasticOut,
      begin: const Offset(0.7, 0.7),
    );
  }

  Widget _dialogButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          color: color.withOpacity(0.12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}