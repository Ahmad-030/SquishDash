import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MenuScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _wobbleController.dispose();
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
        child: Stack(
          children: [
            // Background bubbles
            ..._buildBubbles(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Jelly logo character
                  AnimatedBuilder(
                    animation: _wobbleController,
                    builder: (_, __) {
                      final scaleX = 1.0 + (_wobbleController.value * 0.15);
                      final scaleY = 1.0 - (_wobbleController.value * 0.1);
                      return Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFF9ECD), Color(0xFFFF6B9D)],
                              center: Alignment(-0.3, -0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B9D).withOpacity(0.6),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('😊', style: TextStyle(fontSize: 44)),
                          ),
                        ),
                      );
                    },
                  )
                      .animate()
                      .scale(
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0, 0))
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'SquishDash',
                    style: GoogleFonts.fredoka(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFF6BFFD8)],
                        ).createShader(
                            const Rect.fromLTWH(0, 0, 300, 60)),
                    ),
                  )
                      .animate()
                      .slideY(
                          begin: 0.4,
                          duration: 700.ms,
                          curve: Curves.easeOutBack)
                      .fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Shape-Shifting Runner',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 2,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.3, duration: 500.ms),

                  const SizedBox(height: 60),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF6B9D),
                        ),
                      )
                          .animate(
                              onPlay: (c) => c.repeat(reverse: true),
                              delay: Duration(milliseconds: i * 200))
                          .scaleXY(
                              begin: 0.5,
                              end: 1.0,
                              duration: 500.ms,
                              curve: Curves.easeInOut)
                          .fadeIn(begin: 0.3);
                    }),
                  ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBubbles() {
    final bubbles = [
      _BubbleData(left: 30, top: 80, size: 60, color: const Color(0xFFFF6B9D), opacity: 0.15),
      _BubbleData(right: 40, top: 150, size: 40, color: const Color(0xFF6BFFD8), opacity: 0.12),
      _BubbleData(left: 80, bottom: 200, size: 80, color: const Color(0xFFFFD86B), opacity: 0.10),
      _BubbleData(right: 20, bottom: 300, size: 50, color: const Color(0xFF6B9DFF), opacity: 0.13),
    ];
    return bubbles.map((b) {
      return Positioned(
        left: b.left,
        right: b.right,
        top: b.top,
        bottom: b.bottom,
        child: Container(
          width: b.size,
          height: b.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: b.color.withOpacity(b.opacity),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.8, end: 1.2, duration: 2000.ms, curve: Curves.easeInOut),
      );
    }).toList();
  }
}

class _BubbleData {
  final double? left, right, top, bottom, size;
  final Color color;
  final double opacity;
  const _BubbleData({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });
}
