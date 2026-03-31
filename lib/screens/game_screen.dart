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
  late final Worker _gameOverWorker;

  bool _navigatingAway = false;
  bool _gameHasStarted = false;

  int _countdown = 3;
  bool _showCountdown = true;

  late AnimationController _countdownAnim;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    gc = Get.find<GameController>();
    _navigatingAway = false;
    _gameHasStarted = false;

    _countdownAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _gameOverWorker = ever(gc.gameState, (GameState state) {
      if (_gameHasStarted && state == GameState.gameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToGameOver();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      gc.setScreenSize(size.width, size.height);
      gc.startGame();
      _runCountdown();
    });
  }

  Future<void> _runCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _countdownAnim.forward(from: 0);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() {
      _showCountdown = false;
      _gameHasStarted = true;
    });
    gc.beginPlaying();
  }

  @override
  void dispose() {
    _gameOverWorker.dispose();
    _countdownAnim.dispose();
    _pulseAnim.dispose();
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
      backgroundColor: const Color(0xFF080514),
      body: GestureDetector(
        onPanStart:  (d) => gc.onDragStart(d.localPosition.dx, d.localPosition.dy),
        onPanUpdate: (d) => gc.onDragUpdate(d.localPosition.dx, d.localPosition.dy),
        onPanEnd:    (_) => gc.onDragEnd(),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              // ── Full-screen game world ──
              Obx(() {
                final obstacles = gc.obstacles.toList();
                final ball      = gc.ball.value;
                final sx        = gc.squishX.value;
                final sy        = gc.squishY.value;
                return CustomPaint(
                  size: size,
                  painter: _JellyRunnerPainter(
                    obstacles:  obstacles,
                    ballX:      ball.x,
                    ballScaleX: ball.scaleX * sx,
                    ballScaleY: ball.scaleY * sy,
                    screenSize: size,
                  ),
                );
              }),

              // ── Bottom vignette — blends road into screen edge ──
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: size.height * 0.15,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xDD080514), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),

              // ── HUD ──
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Obx(() => _ScorePanel(
                          score: gc.score.value,
                          best:  gc.scoreController.bestScore.value,
                        )),
                        Obx(() => _SpeedBadge(speed: gc.gameSpeed.value)),
                        _PauseButton(onTap: () {
                          gc.pauseGame();
                          _showPauseDialog(context);
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Shape hint ──
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
                String hint; Color hintColor; IconData hintIcon;
                switch (obs.holeType) {
                  case HoleType.tall:
                    hint = 'STRETCH UP';
                    hintColor = const Color(0xFF00FFD1);
                    hintIcon = Icons.expand_rounded;
                    break;
                  case HoleType.wide:
                    hint = 'SQUISH FLAT';
                    hintColor = const Color(0xFFFFD600);
                    hintIcon = Icons.compress_rounded;
                    break;
                  default:
                    hint = 'ANY SHAPE';
                    hintColor = Colors.white60;
                    hintIcon = Icons.circle_outlined;
                }
                return Positioned(
                  bottom: 52, left: 0, right: 0,
                  child: Center(child: _ShapeHintBadge(
                    hint: hint, color: hintColor, icon: hintIcon,
                  )),
                );
              }),

              // ── Tutorial hint ──
              Obx(() {
                if (gc.score.value > 25) return const SizedBox.shrink();
                return Positioned(
                  bottom: 16, left: 0, right: 0,
                  child: _TutorialHint(pulseAnim: _pulseAnim),
                );
              }),

              // ── Countdown overlay ──
              if (_showCountdown)
                _CountdownOverlay(countdown: _countdown),
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
// HUD Components
// ─────────────────────────────────────────────────────────────────────────────

class _ScorePanel extends StatelessWidget {
  final int score;
  final int best;
  const _ScorePanel({required this.score, required this.best});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.45),
        border: Border.all(
            color: const Color(0xFFFF6B9D).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: GoogleFonts.fredoka(
              fontSize: 42,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.0,
              shadows: [
                Shadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.7),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: const Color(0xFFFFD600), size: 11),
              const SizedBox(width: 3),
              Text(
                'BEST  $best',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: const Color(0xFFFFD600).withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  final double speed;
  const _SpeedBadge({required this.speed});

  @override
  Widget build(BuildContext context) {
    final t = ((speed - 5.0) / 9.0).clamp(0.0, 1.0);
    final color = Color.lerp(
        const Color(0xFF6BFFD8), const Color(0xFFFF4466), t)!;
    const bars = 5;
    final filledBars = (t * bars).ceil().clamp(1, bars);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withOpacity(0.45),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              spreadRadius: -2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SPD',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.white38,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(bars, (i) {
              final filled = i < filledBars;
              return Container(
                width: 4,
                height: 8 + (i * 3.0),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: filled
                      ? color.withOpacity(0.9)
                      : Colors.white.withOpacity(0.08),
                  boxShadow: filled
                      ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)]
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withOpacity(0.45),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: -2),
          ],
        ),
        child: Icon(Icons.pause_rounded, color: Colors.white70, size: 22),
      ),
    );
  }
}

class _ShapeHintBadge extends StatelessWidget {
  final String hint;
  final Color color;
  final IconData icon;
  const _ShapeHintBadge(
      {required this.hint, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 24,
              spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            hint,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
        begin: 0.97,
        end: 1.03,
        duration: 800.ms,
        curve: Curves.easeInOut);
  }
}

class _TutorialHint extends StatelessWidget {
  final AnimationController pulseAnim;
  const _TutorialHint({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Opacity(
        opacity: 0.25 + pulseAnim.value * 0.45,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swipe_rounded,
                      color: Colors.white38, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    'Drag to move  ·  up/down to reshape',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white38,
                        letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Countdown Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CountdownOverlay extends StatelessWidget {
  final int countdown;
  const _CountdownOverlay({required this.countdown});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(
                  parent: anim, curve: Curves.elasticOut),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: countdown > 0
                ? Column(
              key: ValueKey(countdown),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$countdown',
                  style: GoogleFonts.fredoka(
                    fontSize: 140,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFFFF), Color(0xFFFF6B9D)],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 160, 160)),
                  ),
                ),
                Text(
                  'GET READY',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white38,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
                : Column(
              key: const ValueKey('go'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GO!',
                  style: GoogleFonts.fredoka(
                    fontSize: 110,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF00FFD1), Color(0xFF6BFFD8)],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 200, 110)),
                  ),
                ),
                Text(
                  'SQUISH & DASH',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6BFFD8).withOpacity(0.6),
                    letterSpacing: 5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Perspective Painter — horizon at 58% so ground fills full screen
// ─────────────────────────────────────────────────────────────────────────────

class _JellyRunnerPainter extends CustomPainter {
  final List<ObstacleModel> obstacles;
  final double ballX;
  final double ballScaleX;
  final double ballScaleY;
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

  // KEY FIX: horizon pushed down to 58% — road now occupies bottom 42%
  // so there is zero blank space below the game world.
  static const double _horizonY = 0.58;

  Offset _project(double wx, double wy, double wz, Size size) {
    final double relZ = wz + 1.5;
    if (relZ <= 0.001) return const Offset(-9999, -9999);
    final double scale = _fov / relZ;
    return Offset(
      size.width / 2 + wx * scale,
      size.height * _horizonY + (_cameraHeight - wy) * scale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width > 0 && size.height > 0) ? size : screenSize;

    _drawSky(canvas, s);
    _drawStars(canvas, s);
    _drawGround(canvas, s);
    _drawRoad(canvas, s);
    _drawRoadMarkings(canvas, s);

    final sorted = List<ObstacleModel>.from(obstacles)
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final obs in sorted) _drawWall(canvas, s, obs);

    _drawBallShadow(canvas, s);
    _drawBall(canvas, s);
  }

  void _drawSky(Canvas canvas, Size s) {
    final skyRect = Rect.fromLTWH(0, 0, s.width, s.height * _horizonY);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050310),
            Color(0xFF0F0720),
            Color(0xFF1E0C38),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(skyRect),
    );
    // Pink horizon glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * (_horizonY - 0.04)),
        width: s.width * 1.6,
        height: s.height * 0.22,
      ),
      Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    // Teal accent glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * 0.5, s.height * (_horizonY - 0.06)),
        width: s.width * 0.9,
        height: s.height * 0.14,
      ),
      Paint()
        ..color = const Color(0xFF00FFD1).withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  void _drawStars(Canvas canvas, Size s) {
    final stars = [
      [0.08, 0.04, 2.0], [0.22, 0.10, 1.5], [0.48, 0.06, 2.5],
      [0.65, 0.02, 1.8], [0.82, 0.13, 1.5], [0.38, 0.17, 1.2],
      [0.58, 0.20, 2.0], [0.15, 0.25, 1.3], [0.75, 0.08, 1.7],
      [0.92, 0.18, 1.4], [0.30, 0.05, 1.6], [0.55, 0.30, 1.1],
      [0.12, 0.35, 1.3], [0.70, 0.32, 1.4], [0.44, 0.40, 1.0],
      [0.88, 0.38, 1.6], [0.03, 0.50, 1.2], [0.95, 0.44, 1.1],
    ];
    for (final star in stars) {
      final x = s.width * star[0];
      final y = s.height * star[1];
      if (y >= s.height * _horizonY) continue;
      final r = star[2];
      canvas.drawCircle(Offset(x, y), r * 3,
          Paint()
            ..color = Colors.white.withOpacity(0.04)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = Colors.white.withOpacity(0.75));
    }
  }

  void _drawGround(Canvas canvas, Size s) {
    // Ground covers horizon → bottom of screen with no gap
    final groundRect = Rect.fromLTWH(
        0, s.height * _horizonY, s.width, s.height * (1.0 - _horizonY));
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF1C1530),
            Color(0xFF100D1E),
            Color(0xFF080514),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(groundRect),
    );
  }

  void _drawRoad(Canvas canvas, Size s) {
    const zLevels = [0.0, 2.0, 5.0, 10.0, 18.0];
    for (int i = 0; i < zLevels.length - 1; i++) {
      final tl = _project(-1.0, 0.0, zLevels[i + 1], s);
      final tr = _project(1.0, 0.0, zLevels[i + 1], s);
      final bl = _project(-1.0, 0.0, zLevels[i], s);
      final br = _project(1.0, 0.0, zLevels[i], s);
      canvas.drawPath(
        Path()
          ..moveTo(tl.dx, tl.dy)
          ..lineTo(tr.dx, tr.dy)
          ..lineTo(br.dx, br.dy)
          ..lineTo(bl.dx, bl.dy)
          ..close(),
        Paint()
          ..color = Color.lerp(
              const Color(0xFF2E2448),
              const Color(0xFF161026),
              i / (zLevels.length - 1))!,
      );
    }
    for (final wx in [-1.0, 1.0]) {
      canvas.drawLine(
        _project(wx, 0.0, 0.5, s),
        _project(wx, 0.0, 18.0, s),
        Paint()
          ..color = const Color(0xFFFF6B9D).withOpacity(0.25)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawLine(
        _project(wx, 0.0, 0.5, s),
        _project(wx, 0.0, 18.0, s),
        Paint()
          ..color = const Color(0xFFFF6B9D).withOpacity(0.65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawRoadMarkings(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (double z = 1.0; z < 18.0; z += 2.5) {
      final a = _project(0.0, 0.0, z, s);
      final b = _project(0.0, 0.0, z + 1.0, s);
      if (a.dy < s.height * _horizonY) break;
      canvas.drawLine(a, b, paint);
    }
  }

  void _drawWall(Canvas canvas, Size s, ObstacleModel obs) {
    if (obs.z < 0.2) return;
    const wallH = GameController.wallHeight;

    final Color holeGlow;
    switch (obs.holeType) {
      case HoleType.tall:
        holeGlow = const Color(0xFF00FFD1);
        break;
      case HoleType.wide:
        holeGlow = const Color(0xFFFFD600);
        break;
      default:
        holeGlow = const Color(0xFFFF9EFF);
    }

    const wallColor      = Color(0xFFD85520);
    const wallColorDark  = Color(0xFFA83A10);
    const wallColorLight = Color(0xFFFF6B2C);

    void quad(Offset a, Offset b, Offset c, Offset d, Color color) {
      if (a.dx < -5000 || b.dx < -5000) return;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withOpacity(0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }

    Offset p(double wx, double wy)  => _project(wx, wy, obs.z, s);
    Offset pf(double wx, double wy) => _project(wx, wy, obs.z + 0.12, s);

    const wl = -GameController.roadHalfWidth;
    const wr =  GameController.roadHalfWidth;

    if (obs.holeLeft > wl) {
      quad(p(wl, wallH), p(obs.holeLeft, wallH), p(obs.holeLeft, obs.holeTop),
          p(wl, obs.holeTop), wallColor);
      quad(p(wl, obs.holeTop), p(obs.holeLeft, obs.holeTop),
          p(obs.holeLeft, 0), p(wl, 0), wallColorDark);
      quad(p(wl, wallH), p(obs.holeLeft, wallH), pf(obs.holeLeft, wallH),
          pf(wl, wallH), wallColorLight);
    }
    if (obs.holeRight < wr) {
      quad(p(obs.holeRight, wallH), p(wr, wallH), p(wr, obs.holeTop),
          p(obs.holeRight, obs.holeTop), wallColor);
      quad(p(obs.holeRight, obs.holeTop), p(wr, obs.holeTop), p(wr, 0),
          p(obs.holeRight, 0), wallColorDark);
      quad(p(obs.holeRight, wallH), p(wr, wallH), pf(wr, wallH),
          pf(obs.holeRight, wallH), wallColorLight);
    }
    if (obs.holeTop < wallH) {
      quad(p(obs.holeLeft, wallH), p(obs.holeRight, wallH),
          p(obs.holeRight, obs.holeTop), p(obs.holeLeft, obs.holeTop),
          wallColor);
      quad(p(obs.holeLeft, wallH), p(obs.holeRight, wallH),
          pf(obs.holeRight, wallH), pf(obs.holeLeft, wallH), wallColorLight);
    }
    if (obs.holeBottom > 0.0) {
      quad(p(obs.holeLeft, obs.holeBottom), p(obs.holeRight, obs.holeBottom),
          p(obs.holeRight, 0), p(obs.holeLeft, 0), wallColorDark);
    }

    final brickPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (double by = 0.18; by < wallH; by += 0.18) {
      final la = p(wl, by);
      if (la.dy < s.height * _horizonY * 0.2) break;
      canvas.drawLine(la, p(wr, by), brickPaint);
    }
    for (double bx = wl + 0.25; bx < wr; bx += 0.25) {
      canvas.drawLine(p(bx, 0), p(bx, wallH), brickPaint);
    }

    final holePath = Path()
      ..moveTo(p(obs.holeLeft,  obs.holeBottom).dx, p(obs.holeLeft,  obs.holeBottom).dy)
      ..lineTo(p(obs.holeRight, obs.holeBottom).dx, p(obs.holeRight, obs.holeBottom).dy)
      ..lineTo(p(obs.holeRight, obs.holeTop).dx,    p(obs.holeRight, obs.holeTop).dy)
      ..lineTo(p(obs.holeLeft,  obs.holeTop).dx,    p(obs.holeLeft,  obs.holeTop).dy)
      ..close();
    canvas.drawPath(
        holePath,
        Paint()
          ..color = holeGlow.withOpacity(0.1)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        holePath,
        Paint()
          ..color = holeGlow.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(
        holePath,
        Paint()
          ..color = holeGlow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawBallShadow(Canvas canvas, Size s) {
    final center = _project(ballX, 0.0, _roadZ, s);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy - 4),
          width: 44 * ballScaleX,
          height: 9),
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawBall(Canvas canvas, Size s) {
    final center = _project(ballX, 0.24 * ballScaleY, _roadZ, s);
    const double radius = 22.0;
    final double rx = radius * ballScaleX;
    final double ry = radius * ballScaleY;

    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: (rx + 20) * 2, height: (ry + 20) * 2),
      Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: (rx + 7) * 2, height: (ry + 7) * 2),
      Paint()
        ..color = const Color(0xFFFF6B9D).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final ballRect =
    Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      ballRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: const [
            Color(0xFFFFE0EE),
            Color(0xFFFF6B9D),
            Color(0xFFCC3370),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(ballRect),
    );

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx - rx * 0.25, center.dy - ry * 0.3),
          width: rx * 0.5,
          height: ry * 0.28),
      Paint()..color = Colors.white.withOpacity(0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx + rx * 0.2, center.dy - ry * 0.46),
          width: rx * 0.14,
          height: ry * 0.09),
      Paint()..color = Colors.white.withOpacity(0.28),
    );

    final faceSize = (14.0 + (ry - 22.0) * 0.4).clamp(10.0, 26.0);
    final tp = TextPainter(
      text: TextSpan(text: '😊', style: TextStyle(fontSize: faceSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A35), Color(0xFF0D1540)],
          ),
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B9D).withOpacity(0.18),
              blurRadius: 50,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                    color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              child: const Center(
                  child: Text('⏸', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(height: 12),
            Text(
              'PAUSED',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white38,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
            const SizedBox(height: 22),
            _PauseBtn(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              color: const Color(0xFF00FFD1),
              onTap: () {
                Navigator.pop(context);
                gc.resumeGame();
              },
            ),
            const SizedBox(height: 10),
            _PauseBtn(
              label: 'Main Menu',
              icon: Icons.home_rounded,
              color: const Color(0xFFFF6B9D),
              onTap: () {
                gc.pauseGame();
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
            ),
          ],
        ),
      ),
    ).animate().scale(
        duration: 400.ms,
        curve: Curves.elasticOut,
        begin: const Offset(0.75, 0.75));
  }
}

class _PauseBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PauseBtn(
      {required this.label,
        required this.icon,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 18,
                spreadRadius: -2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}