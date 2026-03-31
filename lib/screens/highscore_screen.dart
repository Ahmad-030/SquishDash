import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/score_controller.dart';

class HighscoreScreen extends StatelessWidget {
  const HighscoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ScoreController sc = Get.find();

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
          child: Column(
            children: [
              // Header
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
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Highscores',
                      style: GoogleFonts.fredoka(
                        fontSize: 30,
                        color: const Color(0xFFFFD86B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 10),

              // List
              Expanded(
                child: Obx(() {
                  if (sc.highScores.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎮', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            'No scores yet!',
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Play your first game',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sc.highScores.length,
                    itemBuilder: (_, i) {
                      final score = sc.highScores[i];
                      final isTop3 = i < 3;
                      final medals = ['🥇', '🥈', '🥉'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: isTop3
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFFFFD86B).withOpacity(0.15),
                                    const Color(0xFFFFD86B).withOpacity(0.05),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.07),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                          border: Border.all(
                            color: isTop3
                                ? const Color(0xFFFFD86B).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: isTop3
                                  ? Text(
                                      medals[i],
                                      style:
                                          const TextStyle(fontSize: 22),
                                    )
                                  : Text(
                                      '#${i + 1}',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Run ${i + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                            Text(
                              '$score',
                              style: GoogleFonts.fredoka(
                                fontSize: 28,
                                color: isTop3
                                    ? const Color(0xFFFFD86B)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(delay: Duration(milliseconds: i * 80))
                          .fadeIn(duration: 400.ms)
                          .slideX(
                              begin: 0.2,
                              duration: 400.ms,
                              curve: Curves.easeOutBack);
                    },
                  );
                }),
              ),

              // Clear button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Obx(() {
                  if (sc.highScores.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => _confirmClear(context, sc),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                        color: Colors.red.withOpacity(0.08),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Clear Scores',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, ScoreController sc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0533),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Scores?',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
        content: Text('This will delete all your highscores.',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              sc.clearScores();
              Navigator.pop(context);
            },
            child: Text('Clear',
                style: GoogleFonts.poppins(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
