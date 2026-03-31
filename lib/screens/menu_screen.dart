import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';
import 'game_screen.dart';
import 'highscore_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _jellyController;
  final ScoreController scoreController = Get.find();

  @override
  void initState() {
    super.initState();
    _jellyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _jellyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0533),
              Color(0xFF0D1B4B),
              Color(0xFF0A2A3B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Animated jelly hero
              AnimatedBuilder(
                animation: _jellyController,
                builder: (_, __) {
                  final v = _jellyController.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(1.0 + v * 0.12, 1.0 - v * 0.08),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFB3D1), Color(0xFFFF6B9D)],
                          center: Alignment(-0.3, -0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.5),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  );
                },
              ).animate().scale(
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0, 0)),

              const SizedBox(height: 20),

              Text(
                'SquishDash',
                style: GoogleFonts.fredoka(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFF6BFFD8)],
                    ).createShader(const Rect.fromLTWH(0, 0, 280, 60)),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

              const SizedBox(height: 4),

              Obx(() => Text(
                    scoreController.bestScore.value > 0
                        ? 'Best: ${scoreController.bestScore.value}'
                        : 'Shape. Shift. Survive.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1.5,
                    ),
                  )).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 50),

              // Buttons
              _MenuButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFFFF6B9D),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GameScreen())),
                delay: 400,
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: 'Highscores',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFFFD86B),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HighscoreScreen())),
                delay: 500,
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: 'About',
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF6BFFD8),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen())),
                delay: 600,
              ),
              const SizedBox(height: 16),
              _MenuButton(
                label: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                color: const Color(0xFF6B9DFF),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen())),
                delay: 700,
              ),

              const Spacer(),

              Text(
                'v1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.25),
                ),
              ).animate(delay: 800.ms).fadeIn(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.2),
                  widget.color.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: widget.color.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .slideX(begin: -0.3, duration: 500.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms);
  }
}
