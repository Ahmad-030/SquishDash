import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/obstacle_model.dart';
import '../models/ball_model.dart';
import 'score_controller.dart';

enum GameState { idle, playing, paused, gameOver }

enum HoleType { normal, tall, wide }

class GameController extends GetxController with GetTickerProviderStateMixin {
  final ScoreController scoreController = Get.find();

  final Rx<GameState> gameState = GameState.idle.obs;
  final RxList<ObstacleModel> obstacles = <ObstacleModel>[].obs;
  final Rx<BallModel> ball = const BallModel().obs;
  final RxInt score = 0.obs;
  final RxDouble gameSpeed = 5.0.obs;

  final RxDouble squishX = 1.0.obs;
  final RxDouble squishY = 1.0.obs;

  static const double roadHalfWidth = 1.0;
  static const double wallHeight    = 1.0;
  static const double spawnZ        = 18.0;
  static const double despawnZ      = -1.0;
  static const double collisionZ    = 0.0;

  double _dragStartX      = 0;
  double _dragStartY      = 0;
  double _ballStartX      = 0;
  double _ballStartScaleY = 1.0;

  Timer? _gameLoop;
  Timer? _speedIncreaser;
  Timer? _squishTimer;
  Timer? _firstObstacleDelay;

  final Random _random = Random();

  double screenWidth  = 400;
  double screenHeight = 800;

  double _timeSinceLastSpawn = 0;
  double _spawnInterval      = 3.5;

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
    // Cancel ALL timers first — critical to prevent stale loops from a
    // previous round firing immediately and ending the new game.
    _cancelTimers();

    obstacles.clear();
    ball.value          = const BallModel(x: 0.0, scaleX: 1.0, scaleY: 1.0);
    score.value         = 0;
    gameSpeed.value     = 5.0;
    squishX.value       = 1.0;
    squishY.value       = 1.0;
    _timeSinceLastSpawn = 0;
    _spawnInterval      = 3.5;

    // KEY FIX: Always force back to idle regardless of previous state
    // (paused, gameOver, etc.) so beginPlaying() guard passes correctly.
    gameState.value = GameState.idle;
  }

  void beginPlaying() {
    // KEY FIX: Accept idle OR paused state to handle edge cases where
    // dispose() fires pauseGame() just before/during startGame() reset.
    if (gameState.value != GameState.idle &&
        gameState.value != GameState.paused) return;
    gameState.value = GameState.playing;
    _startLoops();
  }

  void pauseGame() {
    _cancelTimers();
    // Only transition to paused if currently playing; otherwise leave as-is
    // (e.g. idle state should remain idle so beginPlaying() works correctly).
    if (gameState.value == GameState.playing) {
      gameState.value = GameState.paused;
    }
  }

  void resumeGame() {
    if (gameState.value != GameState.paused) return;
    gameState.value = GameState.playing;
    _startLoops();
  }

  void _endGame() {
    _cancelTimers();
    gameState.value = GameState.gameOver;
    scoreController.submitScore(score.value);
  }

  void _cancelTimers() {
    _gameLoop?.cancel();          _gameLoop = null;
    _speedIncreaser?.cancel();    _speedIncreaser = null;
    _squishTimer?.cancel();       _squishTimer = null;
    _firstObstacleDelay?.cancel();_firstObstacleDelay = null;
  }

  void _startLoops() {
    const dt = 0.016;
    _gameLoop = Timer.periodic(
      const Duration(milliseconds: 16),
          (_) => _update(dt),
    );

    _speedIncreaser = Timer.periodic(const Duration(seconds: 5), (_) {
      gameSpeed.value = (gameSpeed.value + 0.4).clamp(5.0, 14.0);
      _spawnInterval  = (_spawnInterval  - 0.1).clamp(1.8, 3.5);
    });

    _firstObstacleDelay = Timer(const Duration(milliseconds: 2500), () {
      if (gameState.value == GameState.playing) _spawnObstacle();
    });
  }

  // ─── Spawning ─────────────────────────────────────────────────────────────

  void _spawnObstacle() {
    if (gameState.value != GameState.playing) return;
    _timeSinceLastSpawn = 0;

    final holeType = HoleType.values[_random.nextInt(HoleType.values.length)];

    double holeW, holeH;
    switch (holeType) {
      case HoleType.tall:
        holeW = _random.nextDouble() * 0.2 + 0.35;
        holeH = _random.nextDouble() * 0.15 + 0.65;
        break;
      case HoleType.wide:
        holeW = _random.nextDouble() * 0.3 + 0.8;
        holeH = _random.nextDouble() * 0.1 + 0.28;
        break;
      case HoleType.normal:
      default:
        holeW = _random.nextDouble() * 0.5 + 0.7;
        holeH = _random.nextDouble() * 0.25 + 0.4;
        break;
    }

    final double maxShift   = (roadHalfWidth * 2 - holeW) / 2 - 0.05;
    final double holeCenter = (_random.nextDouble() * 2 - 1) * maxShift.clamp(0.0, 0.6);
    final double holeLeft   = holeCenter - holeW / 2;
    final double holeRight  = holeCenter + holeW / 2;

    obstacles.add(ObstacleModel(
      z:         spawnZ,
      holeLeft:  holeLeft,
      holeRight: holeRight,
      holeTop:   holeH,
      holeType:  holeType,
    ));
  }

  // ─── Update loop ──────────────────────────────────────────────────────────

  void _update(double dt) {
    if (gameState.value != GameState.playing) return;

    score.value += 1;

    final double dz = gameSpeed.value * dt;
    _timeSinceLastSpawn += dt;
    if (_timeSinceLastSpawn >= _spawnInterval) {
      _spawnObstacle();
    }

    final List<ObstacleModel> updated = [];
    bool hit = false;

    final b = ball.value;

    final double playerScaleY = b.scaleY.clamp(0.5, 1.8);
    final double ballHalfW    = (0.22 / playerScaleY).clamp(0.08, 0.35);
    final double ballH        = 0.48 * playerScaleY;
    const double tolerance    = 0.04;

    final double ballLeft   = b.x - ballHalfW + tolerance;
    final double ballRight  = b.x + ballHalfW - tolerance;
    final double ballBottom = 0.0 + tolerance;
    final double ballTop    = ballH - tolerance;

    for (final obs in obstacles) {
      obs.z -= dz;

      if (!obs.passed && obs.z <= collisionZ + 0.3 && obs.z >= collisionZ - 0.3) {
        obs.passed = true;

        final bool inHoleX = ballLeft  >= obs.holeLeft   && ballRight  <= obs.holeRight;
        final bool inHoleY = ballBottom >= obs.holeBottom && ballTop    <= obs.holeTop;

        if (inHoleX && inHoleY) {
          _triggerSquish();
          score.value += 10;
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

  void onDragStart(double screenX, double screenY) {
    _dragStartX      = screenX;
    _dragStartY      = screenY;
    _ballStartX      = ball.value.x;
    _ballStartScaleY = ball.value.scaleY;
  }

  void onDragUpdate(double screenX, double screenY) {
    if (gameState.value != GameState.playing) return;

    final double dx     = (screenX - _dragStartX) / (screenWidth / 2);
    final double newX   = (_ballStartX + dx * 1.4)
        .clamp(-roadHalfWidth + 0.26, roadHalfWidth - 0.26);

    final double dy        = (screenY - _dragStartY) / (screenHeight * 0.3);
    final double newScaleY = (_ballStartScaleY - dy * 1.2).clamp(0.5, 1.8);
    final double newScaleX = (1.0 / newScaleY).clamp(0.6, 1.6);

    ball.value = ball.value.copyWith(
      x:      newX,
      scaleX: newScaleX,
      scaleY: newScaleY,
    );
  }

  void onDragEnd() {
    _squishTimer?.cancel();
    _squishTimer = Timer(const Duration(milliseconds: 200), () {
      if (gameState.value == GameState.playing) {
        ball.value = ball.value.copyWith(scaleX: 1.0, scaleY: 1.0);
      }
    });
  }
}