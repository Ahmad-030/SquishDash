import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/obstacle_model.dart';
import '../models/ball_model.dart';
import 'score_controller.dart';

enum GameState { idle, playing, paused, gameOver }

// What shape the hole demands from the ball
enum HoleType { normal, tall, wide }

class GameController extends GetxController with GetTickerProviderStateMixin {
  final ScoreController scoreController = Get.find();

  final Rx<GameState> gameState = GameState.idle.obs;
  final RxList<ObstacleModel> obstacles = <ObstacleModel>[].obs;
  final Rx<BallModel> ball = const BallModel().obs;
  final RxInt score = 0.obs;
  final RxDouble gameSpeed = 5.0.obs;

  // Squish animation (triggered on passing through a hole)
  final RxDouble squishX = 1.0.obs;
  final RxDouble squishY = 1.0.obs;

  // Road parameters in world units
  static const double roadHalfWidth = 1.0;
  static const double wallHeight    = 1.0;
  static const double spawnZ        = 18.0;
  static const double despawnZ      = -1.0;
  static const double collisionZ    = 0.0;

  // Drag state
  double _dragStartX    = 0;
  double _dragStartY    = 0;
  double _ballStartX    = 0;
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
    // Always cancel any running timers first — prevents stale loops
    // from a previous round immediately ending the new game.
    _cancelTimers();

    obstacles.clear();
    ball.value          = const BallModel(x: 0.0, scaleX: 1.0, scaleY: 1.0);
    score.value         = 0;
    gameSpeed.value     = 5.0;
    squishX.value       = 1.0;
    squishY.value       = 1.0;
    _timeSinceLastSpawn = 0;
    _spawnInterval      = 3.5;
    gameState.value     = GameState.idle; // idle until GameScreen calls beginPlaying()
  }

  // Called by GameScreen once it has fully initialised and the countdown starts.
  // Separating reset from loop-start prevents timer overlap across rounds.
  void beginPlaying() {
    if (gameState.value != GameState.idle) return;
    gameState.value = GameState.playing;
    _startLoops();
  }

  void pauseGame() {
    // Cancel timers regardless of state so dispose() is always safe.
    _cancelTimers();
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

    // Pick a random hole type — this determines what shape the ball must be
    final holeType = HoleType.values[_random.nextInt(HoleType.values.length)];

    double holeW, holeH;

    switch (holeType) {
      case HoleType.tall:
      // Tall narrow hole — ball must be stretched vertically (scaleY > 1.2)
        holeW = _random.nextDouble() * 0.2 + 0.35; // 0.35..0.55 — narrow
        holeH = _random.nextDouble() * 0.15 + 0.65; // 0.65..0.80 — tall
        break;
      case HoleType.wide:
      // Wide flat hole — ball must be squished (scaleY < 0.8)
        holeW = _random.nextDouble() * 0.3 + 0.8;  // 0.80..1.10 — wide
        holeH = _random.nextDouble() * 0.1 + 0.28; // 0.28..0.38 — short
        break;
      case HoleType.normal:
      default:
      // Normal hole — any ball shape fits
        holeW = _random.nextDouble() * 0.5 + 0.7;  // 0.70..1.20
        holeH = _random.nextDouble() * 0.25 + 0.4; // 0.40..0.65
        break;
    }

    // Hole horizontal centre with random shift
    final double maxShift = (roadHalfWidth * 2 - holeW) / 2 - 0.05;
    final double holeCenter = (_random.nextDouble() * 2 - 1) * maxShift.clamp(0.0, 0.6);
    final double holeLeft   = holeCenter - holeW / 2;
    final double holeRight  = holeCenter + holeW / 2;

    // Hole always starts at ground level — ball cannot jump
    const double holeBottom = 0.0;
    final double holeTop    = holeBottom + holeH;

    obstacles.add(ObstacleModel(
      z:        spawnZ,
      holeLeft: holeLeft,
      holeRight: holeRight,
      holeTop:  holeTop,
      holeType: holeType,
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

    // Ball bounding box is affected by the player's scale choice:
    //   scaleY > 1 → ball is taller and narrower
    //   scaleY < 1 → ball is shorter and wider
    // Base half-width = 0.22, base height = 0.48
    final double playerScaleY = b.scaleY.clamp(0.5, 1.8);
    final double ballHalfW = (0.22 / playerScaleY).clamp(0.08, 0.35);
    final double ballH     = 0.48 * playerScaleY;
    const double tolerance = 0.04;

    final double ballLeft   = b.x - ballHalfW + tolerance;
    final double ballRight  = b.x + ballHalfW - tolerance;
    final double ballBottom = 0.0 + tolerance;
    final double ballTop    = ballH - tolerance;

    for (final obs in obstacles) {
      obs.z -= dz;

      if (!obs.passed && obs.z <= collisionZ + 0.3 && obs.z >= collisionZ - 0.3) {
        obs.passed = true;

        final bool inHoleX = ballLeft  >= obs.holeLeft  && ballRight  <= obs.holeRight;
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

  // ─── Squish animation (on successful pass-through) ────────────────────────

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
    _dragStartX       = screenX;
    _dragStartY       = screenY;
    _ballStartX       = ball.value.x;
    _ballStartScaleY  = ball.value.scaleY;
  }

  void onDragUpdate(double screenX, double screenY) {
    if (gameState.value != GameState.playing) return;

    // Horizontal → move ball left/right
    final double dx    = (screenX - _dragStartX) / (screenWidth / 2);
    final double newX  = (_ballStartX + dx * 1.4)
        .clamp(-roadHalfWidth + 0.26, roadHalfWidth - 0.26);

    // Vertical → stretch / squish ball
    // Drag UP   → scaleY increases (ball gets taller)
    // Drag DOWN → scaleY decreases (ball gets shorter/wider)
    final double dy       = (screenY - _dragStartY) / (screenHeight * 0.3);
    final double newScaleY = (_ballStartScaleY - dy * 1.2) // negative because screen Y is inverted
        .clamp(0.5, 1.8);

    // scaleX is inverse of scaleY to preserve approximate volume
    final double newScaleX = (1.0 / newScaleY).clamp(0.6, 1.6);

    ball.value = ball.value.copyWith(
      x:      newX,
      scaleX: newScaleX,
      scaleY: newScaleY,
    );
  }

  void onDragEnd() {
    // Smoothly snap scale back to normal over next few frames via timer
    _squishTimer?.cancel();
    _squishTimer = Timer(const Duration(milliseconds: 200), () {
      if (gameState.value == GameState.playing) {
        ball.value = ball.value.copyWith(scaleX: 1.0, scaleY: 1.0);
      }
    });
  }
}