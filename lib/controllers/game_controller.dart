import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/obstacle_model.dart';
import '../models/jelly_model.dart';
import 'score_controller.dart';

enum GameState { idle, playing, paused, gameOver }

class GameController extends GetxController with GetTickerProviderStateMixin {
  final ScoreController scoreController = Get.find();

  final Rx<GameState> gameState = GameState.idle.obs;
  final RxList<ObstacleModel> obstacles = <ObstacleModel>[].obs;
  final Rx<JellyModel> jelly = JellyModel().obs;

  final RxDouble gameSpeed = 300.0.obs;
  final RxInt displayScore = 0.obs;

  late AnimationController jellyWobbleController;

  Timer? _gameLoop;
  Timer? _obstacleSpawner;
  Timer? _speedIncreaser;

  final Random _random = Random();

  double screenWidth = 400;
  double screenHeight = 800;

  static const double trackWidth = 300;
  static const double obstacleSpawnSeconds = 1.8;

  @override
  void onInit() {
    super.onInit();
    jellyWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void onClose() {
    jellyWobbleController.dispose();
    _cancelTimers();
    super.onClose();
  }

  void setScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  void startGame() {
    obstacles.clear();
    jelly.value = JellyModel();
    displayScore.value = 0;
    gameSpeed.value = 300;
    gameState.value = GameState.playing;
    _startLoops();
  }

  void pauseGame() {
    if (gameState.value == GameState.playing) {
      gameState.value = GameState.paused;
      _cancelTimers();
    }
  }

  void resumeGame() {
    if (gameState.value == GameState.paused) {
      gameState.value = GameState.playing;
      _startLoops();
    }
  }

  void _endGame() {
    gameState.value = GameState.gameOver;
    _cancelTimers();
    scoreController.submitScore(displayScore.value);
  }

  void _cancelTimers() {
    _gameLoop?.cancel();
    _obstacleSpawner?.cancel();
    _speedIncreaser?.cancel();
  }

  void _startLoops() {
    const frameDuration = Duration(milliseconds: 16);
    _gameLoop = Timer.periodic(frameDuration, (_) => _update(0.016));
    _obstacleSpawner = Timer.periodic(
      Duration(milliseconds: (obstacleSpawnSeconds * 1000).toInt()),
      (_) => _spawnObstacle(),
    );
    _speedIncreaser = Timer.periodic(const Duration(seconds: 5), (_) {
      gameSpeed.value = (gameSpeed.value + 25).clamp(300.0, 900.0);
    });
    _spawnObstacle();
  }

  void _spawnObstacle() {
    if (gameState.value != GameState.playing) return;

    final double gapH = _random.nextDouble() * 70 + 90;
    final double gapW = _random.nextDouble() * 50 + 90;
    final double leftBound = (screenWidth - trackWidth) / 2;
    final double gapX = leftBound + _random.nextDouble() * (trackWidth - gapW);
    final double gapY = _random.nextDouble() * (screenHeight * 0.4) + screenHeight * 0.2;
    final ShapeType shape = ShapeType.values[_random.nextInt(ShapeType.values.length)];

    obstacles.add(ObstacleModel(
      x: screenWidth + 50,
      gapX: gapX,
      gapY: gapY,
      gapWidth: gapW,
      gapHeight: gapH,
      shapeType: shape,
    ));
  }

  void _update(double dt) {
    if (gameState.value != GameState.playing) return;

    displayScore.value += 1;

    final double dx = gameSpeed.value * dt;
    final List<ObstacleModel> updated = [];
    bool hit = false;

    final jellyModel = jelly.value;
    final double jellyLeft = jellyModel.x - jellyModel.width / 2;
    final double jellyRight = jellyModel.x + jellyModel.width / 2;
    final double jellyTop = jellyModel.y - jellyModel.height / 2;
    final double jellyBottom = jellyModel.y + jellyModel.height / 2;

    for (final obs in obstacles) {
      obs.x -= dx;

      // Check collision: obstacle at jelly's depth
      if (obs.x < screenWidth * 0.5 + 40 && obs.x > screenWidth * 0.5 - 40) {
        final double gapLeft = obs.gapX;
        final double gapRight = obs.gapX + obs.gapWidth;
        final double gapTop = obs.gapY;
        final double gapBottom = obs.gapY + obs.gapHeight;

        final bool inGapX = jellyLeft >= gapLeft && jellyRight <= gapRight;
        final bool inGapY = jellyTop >= gapTop && jellyBottom <= gapBottom;

        if (!(inGapX && inGapY)) {
          hit = true;
        }
      }

      if (obs.x > -100) updated.add(obs);
    }

    obstacles.value = updated;

    if (hit) _endGame();
  }

  void onSwipeUp() {
    if (gameState.value != GameState.playing) return;
    final j = jelly.value;
    jelly.value = j.copyWith(
      height: (j.height + 20).clamp(40.0, 150.0),
      width: (j.width - 10).clamp(30.0, 120.0),
    );
  }

  void onSwipeDown() {
    if (gameState.value != GameState.playing) return;
    final j = jelly.value;
    jelly.value = j.copyWith(
      height: (j.height - 20).clamp(40.0, 150.0),
      width: (j.width + 10).clamp(30.0, 120.0),
    );
  }

  void onSwipeLeft() {
    if (gameState.value != GameState.playing) return;
    final j = jelly.value;
    jelly.value = j.copyWith(x: (j.x - 30).clamp(80.0, screenWidth - 80));
  }

  void onSwipeRight() {
    if (gameState.value != GameState.playing) return;
    final j = jelly.value;
    jelly.value = j.copyWith(x: (j.x + 30).clamp(80.0, screenWidth - 80));
  }
}
