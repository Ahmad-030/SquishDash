import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreController extends GetxController {
  final RxList<int> highScores = <int>[].obs;
  final RxInt bestScore = 0.obs;

  static const String _key = 'high_scores_v2';

  @override
  void onInit() {
    super.onInit();
    loadScores();
  }

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList(_key) ?? [];
    highScores.value = stored.map((s) => int.tryParse(s) ?? 0).toList();
    if (highScores.isNotEmpty) {
      bestScore.value = highScores.reduce((a, b) => a > b ? a : b);
    }
  }

  Future<void> submitScore(int score) async {
    highScores.add(score);
    highScores.sort((a, b) => b.compareTo(a));
    if (highScores.length > 10) highScores.removeRange(10, highScores.length);
    if (highScores.isNotEmpty) bestScore.value = highScores.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, highScores.map((s) => s.toString()).toList());
  }

  Future<void> clearScores() async {
    highScores.clear();
    bestScore.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}