import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _jellyController;

  @override
  void initState() {
    super.initState();
    _jellyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
            colors: [Color(0xFF1A0533), Color(0xFF0D1B4B), Color(0xFF0A2A3B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'About',
                      style: GoogleFonts.fredoka(
                        fontSize: 30,
                        color: const Color(0xFF6BFFD8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // Animated jelly logo
                      AnimatedBuilder(
                        animation: _jellyController,
                        builder: (_, __) {
                          final v = _jellyController.value;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..scale(1.0 + v * 0.1, 1.0 - v * 0.07),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFFFFB3D1),
                                    Color(0xFFFF6B9D)
                                  ],
                                  center: Alignment(-0.3, -0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B9D)
                                        .withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child:
                                    Text('😊', style: TextStyle(fontSize: 44)),
                              ),
                            ),
                          );
                        },
                      )
                          .animate()
                          .scale(
                              duration: 700.ms,
                              curve: Curves.elasticOut,
                              begin: const Offset(0, 0))
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      // App name
                      Text(
                        'SquishDash',
                        style: GoogleFonts.fredoka(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [
                                Color(0xFFFF6B9D),
                                Color(0xFF6BFFD8)
                              ],
                            ).createShader(
                                const Rect.fromLTWH(0, 0, 260, 55)),
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),

                      const SizedBox(height: 4),

                      Text(
                        'Version 1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 1.5,
                        ),
                      ).animate(delay: 300.ms).fadeIn(),

                      const SizedBox(height: 32),

                      // Description card
                      _SectionCard(
                        delay: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🎮',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(
                                  'About the Game',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    color: const Color(0xFF6BFFD8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'SquishDash is a shape-shifting endless runner where you control a wobbly jelly character. '
                              'Stretch, squish, and shift your jelly to fit through oncoming gaps — survive as long as you can!',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.75),
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // How to play card
                      _SectionCard(
                        delay: 500,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🕹️',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(
                                  'How to Play',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    color: const Color(0xFFFFD86B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _ControlRow(
                                emoji: '👆', label: 'Swipe Up', desc: 'Stretch tall'),
                            _ControlRow(
                                emoji: '👇', label: 'Swipe Down', desc: 'Squish flat'),
                            _ControlRow(
                                emoji: '👈', label: 'Swipe Left', desc: 'Move left'),
                            _ControlRow(
                                emoji: '👉', label: 'Swipe Right', desc: 'Move right'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Features card
                      _SectionCard(
                        delay: 600,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('✨',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(
                                  'Features',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    color: const Color(0xFFFF6B9D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _FeatureRow(
                                icon: Icons.speed_rounded,
                                text: 'Progressive speed challenge',
                                color: const Color(0xFFFF6B9D)),
                            _FeatureRow(
                                icon: Icons.wifi_off_rounded,
                                text: 'Fully offline — no internet needed',
                                color: const Color(0xFF6BFFD8)),
                            _FeatureRow(
                                icon: Icons.leaderboard_rounded,
                                text: 'Local highscore board',
                                color: const Color(0xFFFFD86B)),
                            _FeatureRow(
                                icon: Icons.vibration_rounded,
                                text: 'Smooth jelly physics & animations',
                                color: const Color(0xFF6B9DFF)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Developer card
                      _SectionCard(
                        delay: 700,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text('👨‍💻',
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Text(
                                  'Developer',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 20,
                                    color: const Color(0xFF6B9DFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _DevInfoRow(
                              icon: Icons.person_rounded,
                              label: 'Developer',
                              value: 'MR DRAGOS BACALU',
                            ),
                            const SizedBox(height: 10),
                            _DevInfoRow(
                              icon: Icons.email_rounded,
                              label: 'Contact',
                              value: 'Ahmadshah81221@gmail.com',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer
                      Text(
                        'Made with ❤️ & Flutter',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ).animate(delay: 800.ms).fadeIn(),
                      const SizedBox(height: 8),
                      Text(
                        '© 2024 SquishDash. All rights reserved.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ).animate(delay: 900.ms).fadeIn(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const _SectionCard({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: child,
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _ControlRow extends StatelessWidget {
  final String emoji, label, desc;
  const _ControlRow(
      {required this.emoji, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _FeatureRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevInfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DevInfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B9DFF), size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
