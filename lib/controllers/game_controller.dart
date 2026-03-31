import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/obstacle_model.dart';
import '../models/ball_model.dart';
import 'score_controller.dart';

enum GameState { idle, playing, paused, gameOver }

class GameController extends GetxController with GetTickerProviderStateMixin {
  final ScoreController scoreController = Get.find();

  final Rx<GameState> gameState = GameState.idle.obs;
  final RxList<ObstacleModel> obstacles = <ObstacleModel>[].obs;
  final Rx<BallModel> ball = const BallModel().obs;
  final RxInt score = 0.obs;
  final RxDouble gameSpeed = 5.0.obs; // world units per second

  // Squish animation
  final RxDouble squishX = 1.0.obs;
  final RxDouble squishY = 1.0.obs;

  // Road parameters in world units
  static const double roadHalfWidth = 1.0; // road goes from -1 to +1
  static const double wallHeight    = 1.0; // wall is 1 unit tall
  static const double spawnZ        = 18.0; // how far ahead obstacles spawn
  static const double despawnZ      = -1.0;
  static const double collisionZ    = 0.0; // ball is always at z=0

  // Drag state
  double _dragStartX = 0;
  double _ballStartX = 0;

  Timer? _gameLoop;
  Timer? _speedIncreaser;
  Timer? _squishTimer;
  Timer? _firstObstacleDelay;

  final Random _random = Random();

  double screenWidth  = 400;
  double screenHeight = 800;

  double _timeSinceLastSpawn = 0;
  double _spawnInterval      = 3.5; // seconds between obstacles

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _cancelTimers();
    super.onClose();
  }

  void setScreenSize(double w, double h) {
    screenWidth  = w;
    screenHeight = h;
  }

  // ─── Game lifecycle ────────────────────────────────────────────────────────

  void startGame() {
    obstacles.clear();
    ball.value       = const BallModel(x: 0.0, scaleX: 1.0, scaleY: 1.0);
    score.value      = 0;
    gameSpeed.value  = 5.0;
    squishX.value    = 1.0;
    squishY.value    = 1.0;
    _timeSinceLastSpawn = 0;
    _spawnInterval   = 3.5;
    gameState.value  = GameState.playing;
    _startLoops();
  }

  void pauseGame() {
    if (gameState.value != GameState.playing) return;
    gameState.value = GameState.paused;
    _cancelTimers();
  }

  void resumeGame() {
    if (gameState.value != GameState.paused) return;
    gameState.value = GameState.playing;
    _startLoops();
  }

  void _endGame() {
    gameState.value = GameState.gameOver;
    _cancelTimers();
    scoreController.submitScore(score.value);
  }

  void _cancelTimers() {
    _gameLoop?.cancel();
    _speedIncreaser?.cancel();
    _squishTimer?.cancel();
    _firstObstacleDelay?.cancel();
  }

  void _startLoops() {
    const dt = 0.016;
    _gameLoop = Timer.periodic(
      const Duration(milliseconds: 16),
          (_) => _update(dt),
    );

    _speedIncreaser = Timer.periodic(const Duration(seconds: 5), (_) {
      gameSpeed.value  = (gameSpeed.value  + 0.4).clamp(5.0, 14.0);
      _spawnInterval   = (_spawnInterval   - 0.1).clamp(1.8, 3.5);
    });

    // First obstacle after 2.5 seconds
    _firstObstacleDelay = Timer(const Duration(milliseconds: 2500), () {
      if (gameState.value == GameState.playing) _spawnObstacle();
    });
  }

  // ─── Spawning ─────────────────────────────────────────────────────────────

  void _spawnObstacle() {
    if (gameState.value != GameState.playing) return;
    _timeSinceLastSpawn = 0;

    // Hole width: 40–65% of road width
    final double holeW = _random.nextDouble() * 0.5 + 0.7; // 0.7..1.2 world units
    // Hole height: 40–65% of wall height
    final double holeH = _random.nextDouble() * 0.25 + 0.4;

    // Hole horizontal position: centered with random offset
    final double maxShift = (roadHalfWidth * 2 - holeW) / 2 - 0.05;
    final double holeCenter = (_random.nextDouble() * 2 - 1) * maxShift.clamp(0.0, 0.6);
    final double holeLeft  = holeCenter - holeW / 2;
    final double holeRight = holeCenter + holeW / 2;

    // Hole vertical: bottom always touches ground (like Jelly Runner)
    // or floats slightly above
    final bool floatingHole = _random.nextBool();
    final double holeBottom = floatingHole ? _random.nextDouble() * 0.2 : 0.0;
    final double holeTop    = holeBottom + holeH;

    obstacles.add(ObstacleModel(
      z: spawnZ,
      holeLeft:   holeLeft,
      holeRight:  holeRight,
      holeBottom: holeBottom,
      holeTop:    holeTop,
    ));
  }

  // ─── Update loop ──────────────────────────────────────────────────────────

  void _update(double dt) {
    if (gameState.value != GameState.playing) return;

    score.value += 1;

    final double dz = gameSpeed.value * dt;

    // Auto-spawn next obstacle
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _spawnObstacle();
    }

    final List<ObstacleModel> updated = [];
    bool hit = false;

    final b = ball.value;
    // Ball occupies x: b.x ± 0.25 (half-width), y: 0..0.5 (height)
    const double ballHalfW = 0.22;
    const double ballH     = 0.48;
    const double tolerance = 0.04;

    final double ballLeft  = b.x - ballHalfW + tolerance;
    final double ballRight = b.x + ballHalfW - tolerance;
    const double ballBottom = 0.0 + tolerance;
    const double ballTop    = ballH - tolerance;

    for (final obs in obstacles) {
      obs.z -= dz;

      // Collision: check when obstacle reaches ball's Z plane
      if (!obs.passed && obs.z <= collisionZ + 0.3 && obs.z >= collisionZ - 0.3) {
        obs.passed = true;

        // Is ball inside the hole?
        final bool inHoleX = ballLeft  >= obs.holeLeft  && ballRight  <= obs.holeRight;
        final bool inHoleY = ballBottom >= obs.holeBottom && ballTop    <= obs.holeTop;

        if (inHoleX && inHoleY) {
          // Passed through! Squish animation
          _triggerSquish();
          score.value += 10; // bonus for clean pass
        } else {
          hit = true;
        }
      }

      if (obs.z > despawnZ) updated.add(obs);
    }

    obstacles.value = updated;
    if (hit) _endGame();
  }

  // ─── Squish animation ─────────────────────────────────────────────────────

  void _triggerSquish() {
    squishX.value = 1.4;
    squishY.value = 0.7;
    _squishTimer?.cancel();
    _squishTimer = Timer(const Duration(milliseconds: 120), () {
      squishX.value = 0.8;
      squishY.value = 1.2;
      _squishTimer = Timer(const Duration(milliseconds: 100), () {
        squishX.value = 1.0;
        squishY.value = 1.0;
      });
    });
  }

  // ─── Input ────────────────────────────────────────────────────────────────

  void onDragStart(double screenX) {
    _dragStartX = screenX;
    _ballStartX = ball.value.x;
  }

  void onDragUpdate(double screenX) {
    if (gameState.value != GameState.playing) return;
    // Map screen drag to world X movement
    final double delta = (screenX - _dragStartX) / (screenWidth / 2);
    final double newX  = (_ballStartX + delta * 1.4)
        .clamp(-roadHalfWidth + 0.26, roadHalfWidth - 0.26);
    ball.value = ball.value.copyWith(x: newX);
  }

  void onDragEnd() {
    // Nothing — ball stays where dragged
  }
}