import 'dart:math';
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
      gc.startGame();   // resets state + cancels old timers, sets idle
      _runCountdown();  // countdown finishes → calls gc.beginPlaying()
    });
  }

  void _runCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _countdownAnim.forward(from: 0);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _showCountdown = false);
    gc.beginPlaying(); // start the game loop AFTER countdown finishes
  }

  @override
  void dispose() {
    _countdownAnim.dispose();
    // Always stop the loop when this screen is disposed —
    // covers play-again, menu navigation, and back gestures.
    gc.pauseGame();
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
        // Both axes wired: X = move left/right, Y = stretch/squish
        onPanStart:  (d) => gc.onDragStart(d.localPosition.dx, d.localPosition.dy),
        onPanUpdate: (d) => gc.onDragUpdate(d.localPosition.dx, d.localPosition.dy),
        onPanEnd:    (_) => gc.onDragEnd(),
        child: Container(
          width: size.width,
          height: size.height,
          color: const Color(0xFF1A1A2E),
          child: Stack(
            children: [
              // 3D Game World
              Obx(() {
                final obstacles = gc.obstacles.toList();
                final ball      = gc.ball.value;
                final sx        = gc.squishX.value;
                final sy        = gc.squishY.value;

                return SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    size: size,
                    painter: _JellyRunnerPainter(
                      obstacles:  obstacles,
                      ballX:      ball.x,
                      ballScaleX: ball.scaleX * sx,
                      ballScaleY: ball.scaleY * sy,
                      screenSize: size,
                    ),
                  ),
                );
              }),

              // HUD
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            Text(
                              'Best: ${gc.scoreController.bestScore.value}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        )),
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

              // Shape hint — shows what the nearest upcoming wall needs
              Obx(() {
                final obs = gc.obstacles
                    .where((o) => !o.passed)
                    .fold<ObstacleModel?>(null, (prev, o) {
                  if (prev == null || o.z < prev.z) return o;
                  return prev;
                });
                if (obs == null || gc.score.value < 5) {
                  return const SizedBox.shrink();
                }

                String hint;
                Color hintColor;
                IconData hintIcon;

                switch (obs.holeType) {
                  case HoleType.tall:
                    hint      = 'Stretch UP!';
                    hintColor = const Color(0xFF6BFFD8);
                    hintIcon  = Icons.height_rounded;
                    break;
                  case HoleType.wide:
                    hint      = 'Squish FLAT!';
                    hintColor = const Color(0xFFFFD86B);
                    hintIcon  = Icons.swap_vert_rounded;
                    break;
                  default:
                    hint      = 'Any shape';
                    hintColor = Colors.white54;
                    hintIcon  = Icons.circle_outlined;
                }

                return Positioned(
                  bottom: 80, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: hintColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: hintColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(hintIcon, color: hintColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            hint,
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Early-game drag hint
              Obx(() {
                if (gc.score.value > 25) return const SizedBox.shrink();
                return Positioned(
                  bottom: 40, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_with_rounded,
                          color: Colors.white38, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Drag left/right to move  •  up/down to reshape',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 800.ms)
                      .then()
                      .fadeOut(duration: 800.ms),
                );
              }),

              // Countdown overlay
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

              // Game-over listener
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
  final double ballScaleX; // combined player scaleX × squish
  final double ballScaleY; // combined player scaleY × squish
  final Size screenSize;

  _JellyRunnerPainter({
    required this.obstacles,
    required this.ballX,
    required this.ballScaleX,
    required this.ballScaleY,
    required this.screenSize,
  });

  static const double _cameraHeight = 0.55;
  static const double _fov          = 280.0;
  static const double _roadZ        = 0.0;

  Offset _project(double wx, double wy, double wz, Size size) {
    final double relZ = wz + 1.5;
    if (relZ <= 0.001) return const Offset(-9999, -9999);
    final double scale = _fov / relZ;
    return Offset(
      size.width  / 2 + wx * scale,
      size.height * 0.42 + (_cameraHeight - wy) * scale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width > 0 && size.height > 0) ? size : screenSize;

    // Sky
    final skyRect = Rect.fromLTWH(0, 0, s.width, s.height * 0.42);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A2E), Color(0xFF3B1F6B)],
        ).createShader(skyRect),
    );

    // Stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.5);
    for (final p in [
      Offset(s.width * 0.10, s.height * 0.05),
      Offset(s.width * 0.25, s.height * 0.12),
      Offset(s.width * 0.50, s.height * 0.07),
      Offset(s.width * 0.70, s.height * 0.03),
      Offset(s.width * 0.85, s.height * 0.15),
      Offset(s.width * 0.40, s.height * 0.18),
      Offset(s.width * 0.60, s.height * 0.22),
    ]) {
      if (p.dy < s.height * 0.42) canvas.drawCircle(p, 1.5, starPaint);
    }

    // Ground
    final groundRect = Rect.fromLTWH(0, s.height * 0.42, s.width, s.height * 0.58);
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C3E), Color(0xFF1A1A2E)],
        ).createShader(groundRect),
    );

    _drawRoad(canvas, s);
    _drawRoadMarkings(canvas, s);

    final sorted = List<ObstacleModel>.from(obstacles)
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final obs in sorted) _drawWall(canvas, s, obs);

    _drawBallShadow(canvas, s);
    _drawBall(canvas, s);
  }

  void _drawRoad(Canvas canvas, Size s) {
    const zLevels = [0.0, 2.0, 5.0, 10.0, 18.0];
    for (int i = 0; i < zLevels.length - 1; i++) {
      final tl = _project(-1.0, 0.0, zLevels[i + 1], s);
      final tr = _project( 1.0, 0.0, zLevels[i + 1], s);
      final bl = _project(-1.0, 0.0, zLevels[i],     s);
      final br = _project( 1.0, 0.0, zLevels[i],     s);
      canvas.drawPath(
        Path()
          ..moveTo(tl.dx, tl.dy) ..lineTo(tr.dx, tr.dy)
          ..lineTo(br.dx, br.dy) ..lineTo(bl.dx, bl.dy) ..close(),
        Paint()
          ..color = Color.lerp(const Color(0xFF3A3A5C),
              const Color(0xFF2A2A42), i / (zLevels.length - 1))!,
      );
    }
    for (final wx in [-1.0, 1.0]) {
      canvas.drawLine(
        _project(wx, 0.0, 0.5, s), _project(wx, 0.0, 18.0, s),
        Paint()
          ..color = const Color(0xFFFF6B9D).withOpacity(0.4)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawRoadMarkings(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (double z = 1.0; z < 18.0; z += 2.5) {
      final a = _project(0.0, 0.0, z,       s);
      final b = _project(0.0, 0.0, z + 1.0, s);
      if (a.dy < s.height * 0.42) break;
      canvas.drawLine(a, b, paint);
    }
  }

  void _drawWall(Canvas canvas, Size s, ObstacleModel obs) {
    if (obs.z < 0.2) return;
    const wallH = GameController.wallHeight;

    // Hole border colour encodes the required ball shape
    final Color holeGlow;
    switch (obs.holeType) {
      case HoleType.tall:
        holeGlow = const Color(0xFF6BFFD8); // teal = drag up to stretch
        break;
      case HoleType.wide:
        holeGlow = const Color(0xFFFFD86B); // gold = drag down to squish
        break;
      default:
        holeGlow = const Color(0xFFFFE57A); // yellow = any shape ok
    }

    const wallColor      = Color(0xFFE8622A);
    const wallColorDark  = Color(0xFFC04A18);
    const wallColorLight = Color(0xFFFF7A3C);

    void quad(Offset a, Offset b, Offset c, Offset d, Color color) {
      if (a.dx < -5000 || b.dx < -5000) return;
      final path = Path()
        ..moveTo(a.dx, a.dy) ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy) ..lineTo(d.dx, d.dy) ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke ..strokeWidth = 1.0);
    }

    Offset p(double wx, double wy) => _project(wx, wy, obs.z, s);
    Offset pf(double wx, double wy) => _project(wx, wy, obs.z + 0.12, s);

    const wl = -GameController.roadHalfWidth;
    const wr =  GameController.roadHalfWidth;

    if (obs.holeLeft > wl) {
      quad(p(wl, wallH), p(obs.holeLeft, wallH), p(obs.holeLeft, obs.holeTop), p(wl, obs.holeTop), wallColor);
      quad(p(wl, obs.holeTop), p(obs.holeLeft, obs.holeTop), p(obs.holeLeft, 0), p(wl, 0), wallColorDark);
      quad(p(wl, wallH), p(obs.holeLeft, wallH), pf(obs.holeLeft, wallH), pf(wl, wallH), wallColorLight);
    }
    if (obs.holeRight < wr) {
      quad(p(obs.holeRight, wallH), p(wr, wallH), p(wr, obs.holeTop), p(obs.holeRight, obs.holeTop), wallColor);
      quad(p(obs.holeRight, obs.holeTop), p(wr, obs.holeTop), p(wr, 0), p(obs.holeRight, 0), wallColorDark);
      quad(p(obs.holeRight, wallH), p(wr, wallH), pf(wr, wallH), pf(obs.holeRight, wallH), wallColorLight);
    }
    if (obs.holeTop < wallH) {
      quad(p(obs.holeLeft, wallH), p(obs.holeRight, wallH), p(obs.holeRight, obs.holeTop), p(obs.holeLeft, obs.holeTop), wallColor);
      quad(p(obs.holeLeft, wallH), p(obs.holeRight, wallH), pf(obs.holeRight, wallH), pf(obs.holeLeft, wallH), wallColorLight);
    }
    if (obs.holeBottom > 0.0) {
      quad(p(obs.holeLeft, obs.holeBottom), p(obs.holeRight, obs.holeBottom), p(obs.holeRight, 0), p(obs.holeLeft, 0), wallColorDark);
    }

    // Brick lines
    final brickPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 1.2 ..style = PaintingStyle.stroke;
    for (double by = 0.18; by < wallH; by += 0.18) {
      final la = p(wl, by); if (la.dy < s.height * 0.1) break;
      canvas.drawLine(la, p(wr, by), brickPaint);
    }
    for (double bx = wl + 0.25; bx < wr; bx += 0.25) {
      canvas.drawLine(p(bx, 0), p(bx, wallH), brickPaint);
    }

    // Coloured hole glow
    canvas.drawPath(
      Path()
        ..moveTo(p(obs.holeLeft, obs.holeBottom).dx, p(obs.holeLeft, obs.holeBottom).dy)
        ..lineTo(p(obs.holeRight, obs.holeBottom).dx, p(obs.holeRight, obs.holeBottom).dy)
        ..lineTo(p(obs.holeRight, obs.holeTop).dx, p(obs.holeRight, obs.holeTop).dy)
        ..lineTo(p(obs.holeLeft, obs.holeTop).dx, p(obs.holeLeft, obs.holeTop).dy)
        ..close(),
      Paint()
        ..color = holeGlow.withOpacity(0.75)
        ..style = PaintingStyle.stroke ..strokeWidth = 3.0,
    );
  }

  void _drawBallShadow(Canvas canvas, Size s) {
    final center = _project(ballX, 0.0, _roadZ, s);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy - 4),
          width: 45 * ballScaleX, height: 10),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawBall(Canvas canvas, Size s) {
    // Centre Y rises when ball stretches tall
    final center = _project(ballX, 0.24 * ballScaleY, _roadZ, s);
    const double radius = 22.0;
    final double rx = radius * ballScaleX;
    final double ry = radius * ballScaleY;

    // Glow
    canvas.drawOval(
      Rect.fromCenter(center: center, width: (rx + 14) * 2, height: (ry + 14) * 2),
      Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Body
    final ballRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      ballRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: const [Color(0xFFFFD1E8), Color(0xFFFF6B9D), Color(0xFFD63B7A)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(ballRect),
    );

    // Highlight
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx - rx * 0.28, center.dy - ry * 0.3),
          width: rx * 0.55, height: ry * 0.32),
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    // Face (size tracks ball height)
    final faceSize = (14.0 + (ry - 22.0) * 0.4).clamp(10.0, 26.0);
    final tp = TextPainter(
      text: TextSpan(text: '😊', style: TextStyle(fontSize: faceSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_JellyRunnerPainter old) => true;
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('Paused',
                style: GoogleFonts.fredoka(
                    fontSize: 32, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            _btn('Resume', Icons.play_arrow_rounded, const Color(0xFF6BFFD8), () {
              Navigator.pop(context); gc.resumeGame();
            }),
            const SizedBox(height: 14),
            _btn('Menu', Icons.home_rounded, const Color(0xFFFF6B9D), () {
              gc.pauseGame(); // stop loop before navigating away
              Navigator.of(context)..pop()..pop();
            }),
          ],
        ),
      ),
    ).animate().scale(
        duration: 400.ms, curve: Curves.elasticOut,
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
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}