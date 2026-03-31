import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController gc = Get.find();
    final ScoreController sc = Get.find();
    final int finalScore = gc.score.value;
    final bool isNewBest = sc.highScores.isNotEmpty &&
        sc.highScores.first == finalScore &&
        sc.highScores.where((s) => s == finalScore).length == 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😵', style: TextStyle(fontSize: 70))
                      .animate()
                      .scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0, 0))
                      .shake(hz: 3, delay: 300.ms),

                  const SizedBox(height: 20),

                  Text(
                    'Splat!',
                    style: GoogleFonts.fredoka(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFFD93D)],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 60)),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 30),

                  // Score card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.04),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('Score',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text('$finalScore',
                            style: GoogleFonts.fredoka(
                                fontSize: 64,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (isNewBest) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD86B),
                                    Color(0xFFFF9E3B)
                                  ]),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text('New Best!',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(begin: 0.95, end: 1.05, duration: 600.ms),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_outlined,
                                color: Color(0xFFFFD86B), size: 18),
                            const SizedBox(width: 6),
                            Obx(() => Text('Best: ${sc.bestScore.value}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: const Color(0xFFFFD86B),
                                    fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).fadeIn().scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),

                  const SizedBox(height: 40),

                  _Btn(
                    label: 'Play Again',
                    icon: Icons.replay_rounded,
                    color: const Color(0xFFFF6B35),
                    onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const GameScreen())),
                    delay: 500,
                  ),
                  const SizedBox(height: 16),
                  _Btn(
                    label: 'Menu',
                    icon: Icons.home_rounded,
                    color: const Color(0xFF6B9DFF),
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const MenuScreen()),
                            (r) => false),
                    delay: 600,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;
  const _Btn(
      {required this.label,
        required this.icon,
        required this.color,
        required this.onTap,
        required this.delay});

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [
              widget.color.withOpacity(0.25),
              widget.color.withOpacity(0.1)
            ]),
            border: Border.all(
                color: widget.color.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 22),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOutBack);
  }
}