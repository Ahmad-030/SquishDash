import 'dart:math';
import 'dart:ui';
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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameController gc;
  bool _navigatingAway = false;

  // Countdown
  int _countdown = 3;
  bool _showCountdown = true;

  late AnimationController _countdownAnim;

  @override
  void initState() {
    super.initState();
    gc = Get.find<GameController>();
    _navigatingAway = false;

    _countdownAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      gc.setScreenSize(size.width, size.height);
      gc.startGame();
      _runCountdown();
    });
  }

  void _runCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _countdownAnim.forward(from: 0);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted) setState(() => _showCountdown = false);
  }

  @override
  void dispose() {
    _countdownAnim.dispose();
    if (gc.gameState.value == GameState.playing) gc.pauseGame();
    super.dispose();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (d) => gc.onDragStart(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => gc.onDragUpdate(d.localPosition.dx),
        onHorizontalDragEnd: (_) => gc.onDragEnd(),
        // Also support free pan for diagonal swipes
        onPanStart: (d) => gc.onDragStart(d.localPosition.dx),
        onPanUpdate: (d) => gc.onDragUpdate(d.localPosition.dx),
        onPanEnd: (_) => gc.onDragEnd(),
        child: Container(
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
              // ── 3D Game World ──────────────────────────────────────
              Positioned.fill(
                child: Obx(() {
                  // Trigger rebuild on obstacle list or ball change
                  final obstacles = gc.obstacles.toList();
                  final ball      = gc.ball.value;
                  final sx        = gc.squishX.value;
                  final sy        = gc.squishY.value;

                  return CustomPaint(
                    painter: _JellyRunnerPainter(
                      obstacles:  obstacles,
                      ballX:      ball.x,
                      squishX:    sx,
                      squishY:    sy,
                      screenSize: size,
                    ),
                  );
                }),
              ),

              // ── HUD ────────────────────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Score
                        Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${gc.score.value}',
                              style: GoogleFonts.fredoka(
                                fontSize: 38,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            Obx(() => Text(
                              'Best: ${gc.scoreController.bestScore.value}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            )),
                          ],
                        )),
                        // Pause button
                        GestureDetector(
                          onTap: () {
                            gc.pauseGame();
                            _showPauseDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
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

              // ── Drag hint ──────────────────────────────────────────
              Obx(() {
                if (gc.score.value > 20) return const SizedBox.shrink();
                return Positioned(
                  bottom: 50, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swipe_rounded,
                          color: Colors.white38, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Drag left / right to move',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white38),
                      ),
                    ],
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 800.ms)
                      .then()
                      .fadeOut(duration: 800.ms),
                );
              }),

              // ── Countdown overlay ──────────────────────────────────
              if (_showCountdown)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: CurvedAnimation(
                              parent: anim, curve: Curves.elasticOut),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: _countdown > 0
                            ? Text(
                          '$_countdown',
                          key: ValueKey(_countdown),
                          style: GoogleFonts.fredoka(
                            fontSize: 130,
                            fontWeight: FontWeight.w700,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B35),
                                  Color(0xFFFFD93D)
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 150, 150)),
                          ),
                        )
                            : Text(
                          'GO!',
                          key: const ValueKey('go'),
                          style: GoogleFonts.fredoka(
                            fontSize: 90,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6BFFD8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

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
// 3D Perspective Painter
// ─────────────────────────────────────────────────────────────────────────────

class _JellyRunnerPainter extends CustomPainter {
  final List<ObstacleModel> obstacles;
  final double ballX;
  final double squishX;
  final double squishY;
  final Size screenSize;

  _JellyRunnerPainter({
    required this.obstacles,
    required this.ballX,
    required this.squishX,
    required this.squishY,
    required this.screenSize,
  });

  // ── Perspective projection ────────────────────────────────────────────────
  // World: X = -1..1 (road width), Z = 0 (near/ball) .. 20 (far horizon)
  // Y = 0 (ground) .. 1 (wall top)
  //
  // Camera sits slightly above and behind the ball.
  // horizon is at screenH * 0.42, road vanishes there.

  static const double _cameraHeight = 0.55; // world units above ground
  static const double _fov          = 280.0; // focal length in screen pixels equivalent
  static const double _roadZ        = 0.0;   // ball's Z (always 0)

  Offset _project(double wx, double wy, double wz, Size size) {
    // Translate so camera is slightly behind ball (at z = -1.5)
    final double relZ = wz + 1.5;
    if (relZ <= 0) return Offset(-9999, -9999); // behind camera

    final double scale = _fov / relZ;

    // Horizon center
    final double cx = size.width  / 2;
    final double cy = size.height * 0.42;

    final double sx = cx + wx * scale;
    // Y: ground is at cy, higher world Y goes UP on screen
    final double sy = cy + (_cameraHeight - wy) * scale;

    return Offset(sx, sy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFB8E4F9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.42), skyPaint);

    // Ground below horizon
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C2C3E), Color(0xFF1A1A2E)],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.58));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.58),
        groundPaint);

    // ── Road ────────────────────────────────────────────────────────────────
    _drawRoad(canvas, size);

    // ── Road markings ───────────────────────────────────────────────────────
    _drawRoadMarkings(canvas, size);

    // ── Obstacles (back to front) ────────────────────────────────────────────
    final sorted = List<ObstacleModel>.from(obstacles)
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final obs in sorted) {
      _drawWall(canvas, size, obs);
    }

    // ── Ball shadow ──────────────────────────────────────────────────────────
    _drawBallShadow(canvas, size);

    // ── Ball ────────────────────────────────────────────────────────────────
    _drawBall(canvas, size);
  }

  void _drawRoad(Canvas canvas, Size size) {
    // Road: world X = -1..+1, Z = 0..20, Y = 0 (ground level)
    final List<double> zLevels = [0.0, 2.0, 5.0, 10.0, 18.0];
    for (int i = 0; i < zLevels.length - 1; i++) {
      final double z0 = zLevels[i];
      final double z1 = zLevels[i + 1];

      final tl = _project(-1.0, 0.0, z1, size);
      final tr = _project( 1.0, 0.0, z1, size);
      final bl = _project(-1.0, 0.0, z0, size);
      final br = _project( 1.0, 0.0, z0, size);

      // Alternate dark/slightly lighter strips for depth feel
      final double t = i / (zLevels.length - 1);
      final Color c = Color.lerp(
        const Color(0xFF3A3A5C),
        const Color(0xFF2A2A42),
        t,
      )!;

      final path = Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(bl.dx, bl.dy)
        ..close();

      canvas.drawPath(path, Paint()..color = c);
    }

    // Road edges (bright lines)
    _drawRoadEdge(canvas, size, -1.0);
    _drawRoadEdge(canvas, size,  1.0);
  }

  void _drawRoadEdge(Canvas canvas, Size size, double worldX) {
    final near = _project(worldX, 0.0,  0.5, size);
    final far  = _project(worldX, 0.0, 18.0, size);
    canvas.drawLine(
      near, far,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawRoadMarkings(Canvas canvas, Size size) {
    // Dashed center line
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (double z = 1.0; z < 18.0; z += 2.5) {
      final a = _project(0.0, 0.0, z,       size);
      final b = _project(0.0, 0.0, z + 1.0, size);
      if (a.dy < size.height * 0.42) break;
      canvas.drawLine(a, b, paint);
    }
  }

  void _drawWall(Canvas canvas, Size size, ObstacleModel obs) {
    if (obs.z < 0.2) return;

    const double wallH = GameController.wallHeight;

    // The full wall rect (before hole)
    final tl = _project(obs.holeLeft  - 10, wallH, obs.z, size); // full left far
    // We'll draw the wall as 4 regions around the hole:
    // Left slab, right slab, top slab, (bottom slab if floating hole)

    final wallColor      = const Color(0xFFE8622A); // orange brick
    final wallColorDark  = const Color(0xFFC04A18); // darker face
    final wallColorLight = const Color(0xFFFF7A3C); // highlight top

    void drawQuad(Offset a, Offset b, Offset c, Offset d, Color color) {
      if (a.dy < -100 || b.dy < -100) return; // off screen
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      // Outline
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Helper: project a wall point (world x, world y, at obs.z)
    Offset p(double wx, double wy) => _project(wx, wy, obs.z, size);
    // Front face depth offset for thickness
    Offset pf(double wx, double wy) => _project(wx, wy, obs.z + 0.12, size);

    const double wallLeft  = -GameController.roadHalfWidth;
    const double wallRight =  GameController.roadHalfWidth;

    // ── LEFT slab (wall left edge to hole left edge) ──────────────────────
    if (obs.holeLeft > wallLeft) {
      // Front face
      drawQuad(
        p(wallLeft,      wallH),
        p(obs.holeLeft,  wallH),
        p(obs.holeLeft,  obs.holeTop),
        p(wallLeft,      obs.holeTop),
        wallColor,
      );
      // Bottom part of left slab (below hole top to ground)
      drawQuad(
        p(wallLeft,      obs.holeTop),
        p(obs.holeLeft,  obs.holeTop),
        p(obs.holeLeft,  0.0),
        p(wallLeft,      0.0),
        wallColorDark,
      );
      // Top face (thickness)
      drawQuad(
        p(wallLeft,     wallH),
        p(obs.holeLeft, wallH),
        pf(obs.holeLeft, wallH),
        pf(wallLeft,     wallH),
        wallColorLight,
      );
    }

    // ── RIGHT slab (hole right edge to wall right edge) ───────────────────
    if (obs.holeRight < wallRight) {
      drawQuad(
        p(obs.holeRight, wallH),
        p(wallRight,     wallH),
        p(wallRight,     obs.holeTop),
        p(obs.holeRight, obs.holeTop),
        wallColor,
      );
      drawQuad(
        p(obs.holeRight, obs.holeTop),
        p(wallRight,     obs.holeTop),
        p(wallRight,     0.0),
        p(obs.holeRight, 0.0),
        wallColorDark,
      );
      drawQuad(
        p(obs.holeRight, wallH),
        p(wallRight,     wallH),
        pf(wallRight,    wallH),
        pf(obs.holeRight, wallH),
        wallColorLight,
      );
    }

    // ── TOP slab (above the hole, spanning hole width) ─────────────────────
    if (obs.holeTop < wallH) {
      drawQuad(
        p(obs.holeLeft,  wallH),
        p(obs.holeRight, wallH),
        p(obs.holeRight, obs.holeTop),
        p(obs.holeLeft,  obs.holeTop),
        wallColor,
      );
      // Top face
      drawQuad(
        p(obs.holeLeft,  wallH),
        p(obs.holeRight, wallH),
        pf(obs.holeRight, wallH),
        pf(obs.holeLeft,  wallH),
        wallColorLight,
      );
    }

    // ── BOTTOM slab (if hole is floating above ground) ────────────────────
    if (obs.holeBottom > 0.0) {
      drawQuad(
        p(obs.holeLeft,  obs.holeBottom),
        p(obs.holeRight, obs.holeBottom),
        p(obs.holeRight, 0.0),
        p(obs.holeLeft,  0.0),
        wallColorDark,
      );
    }

    // ── Brick texture lines (horizontal) ──────────────────────────────────
    final brickPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double by = 0.18; by < wallH; by += 0.18) {
      final la = p(wallLeft,  by);
      final lb = p(wallRight, by);
      if (la.dy < size.height * 0.1) break;
      canvas.drawLine(la, lb, brickPaint);
    }
    // Vertical brick lines
    for (double bx = wallLeft + 0.25; bx < wallRight; bx += 0.25) {
      final ba = p(bx, 0.0);
      final bb = p(bx, wallH);
      canvas.drawLine(ba, bb, brickPaint);
    }

    // ── Hole outline glow ──────────────────────────────────────────────────
    final glowA = p(obs.holeLeft,  obs.holeBottom);
    final glowB = p(obs.holeRight, obs.holeBottom);
    final glowC = p(obs.holeRight, obs.holeTop);
    final glowD = p(obs.holeLeft,  obs.holeTop);
    final glowPath = Path()
      ..moveTo(glowA.dx, glowA.dy)
      ..lineTo(glowB.dx, glowB.dy)
      ..lineTo(glowC.dx, glowC.dy)
      ..lineTo(glowD.dx, glowD.dy)
      ..close();
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = const Color(0xFFFFE57A).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawBallShadow(Canvas canvas, Size size) {
    final center = _project(ballX, 0.0, _roadZ, size);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 4),
        width:  45 * squishX,
        height: 10,
      ),
      paint,
    );
  }

  void _drawBall(Canvas canvas, Size size) {
    // Ball sits on the road at Z=0, Y=0 (ground level), center at Y=0.24
    final center = _project(ballX, 0.24, _roadZ, size);

    const double radius = 22.0;
    final double rx = radius * squishX;
    final double ry = radius * squishY;

    // Glow
    canvas.drawOval(
      Rect.fromCenter(center: center, width: (rx + 14) * 2, height: (ry + 14) * 2),
      Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Main ball gradient
    final ballRect = Rect.fromCenter(
        center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      ballRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: const [
            Color(0xFFFFD1E8),
            Color(0xFFFF6B9D),
            Color(0xFFD63B7A),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(ballRect),
    );

    // Specular highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - rx * 0.28, center.dy - ry * 0.3),
        width:  rx * 0.55,
        height: ry * 0.32,
      ),
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    // Face emoji — drawn as text
    final tp = TextPainter(
      text: const TextSpan(
          text: '😊', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_JellyRunnerPainter old) =>
      old.ballX      != ballX      ||
          old.squishX    != squishX    ||
          old.squishY    != squishY    ||
          old.obstacles  != obstacles;
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
              color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Paused',
                style: GoogleFonts.fredoka(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            _btn(
              'Resume',
              Icons.play_arrow_rounded,
              const Color(0xFF6BFFD8),
                  () { Navigator.pop(context); gc.resumeGame(); },
            ),
            const SizedBox(height: 14),
            _btn(
              'Menu',
              Icons.home_rounded,
              const Color(0xFFFF6B9D),
                  () {
                gc.startGame();
                Navigator.of(context)..pop()..pop();
              },
            ),
          ],
        ),
      ),
    ).animate().scale(
        duration: 400.ms,
        curve: Curves.elasticOut,
        begin: const Offset(0.7, 0.7));
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
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
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}