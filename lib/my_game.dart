import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/boss.dart'; // NEW IMPORT
import 'package:cosmic_havoc/components/enemy.dart';
import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/health_bar.dart';
import 'package:cosmic_havoc/components/pause_button.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteroidSpawner;
  late SpawnComponent _enemySpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;

  int _score = 0;
  int highScore = 0;

  // NEW: Track if the boss has been spawned
  bool _bossSpawned = false;

  double get difficultyMultiplier => 1.0 + (_score / 500);

  late TextComponent _scoreDisplay;
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;
  late final AudioManager audioManager;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();

    audioManager = AudioManager();
    await add(audioManager);

    await loadHighScore();

    _createStars();

    return super.onLoad();
  }

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
  }

  Future<void> checkNewHighScore() async {
    if (_score > highScore) {
      highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', highScore);
    }
  }

  void startGame() async {
    audioManager.playMusic();
    _bossSpawned = false; // Reset boss state

    await _createJoystick();
    await _createPlayer();
    _createShootButton();
    _createAsteroidSpawner();
    _createEnemySpawner();
    _createPickupSpawner();
    _createScoreDisplay();

    add(HealthBar());
    add(PauseButton());
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  Future<void> _createJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: Vector2.all(100),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(
        position: _generateSpawnPosition(),
        speedMultiplier: difficultyMultiplier,
      ),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createEnemySpawner() {
    _enemySpawner = SpawnComponent.periodRange(
      factory: (index) => Enemy(
        position: _generateSpawnPosition(),
        speedMultiplier: difficultyMultiplier,
      ),
      minPeriod: 2.0,
      maxPeriod: 4.0,
      selfPositioning: true,
    );
    add(_enemySpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 10.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
      10 + _random.nextDouble() * (size.x - 10 * 2),
      -100,
    );
  }

  void _createScoreDisplay() {
    _score = 0;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }

  int get currentScore => _score;

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();

    final ScaleEffect popEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(
        duration: 0.05,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );

    _scoreDisplay.add(popEffect);

    // NEW: Check if we should spawn the boss (Score >= 100)
    if (_score >= 200 && !_bossSpawned) {
      _spawnBoss();
    }
  }

  // NEW: Logic to spawn the Boss
  void _spawnBoss() {
    _bossSpawned = true;

    // Stop spawning regular enemies so the player can focus on the Boss
    _enemySpawner.timer.stop();

    // Add the Boss component
    add(Boss());
  }

  // NEW: Logic called when Boss is destroyed
  void bossDefeated() {
    // Resume spawning regular enemies
    _enemySpawner.timer.start();
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() async {
    await checkNewHighScore();
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    // Remove all game entities
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid ||
          component is Pickup ||
          component is HealthBar ||
          component is Enemy ||
          component is EnemyLaser ||
          component is PauseButton ||
          component is Boss) { // NEW: Ensure Boss is removed on restart
        remove(component);
      }
    });

    // Reset Boss State
    _bossSpawned = false;

    // Restart Spawners
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();
    _enemySpawner.timer.start();

    _score = 0;
    _scoreDisplay.text = '0';

    _createPlayer();

    add(HealthBar());
    add(PauseButton());

    resumeEngine();
  }

  void quitGame() {
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        remove(component);
      }
    });

    remove(_asteroidSpawner);
    remove(_pickupSpawner);
    remove(_enemySpawner);

    overlays.add('Title');

    resumeEngine();
  }
}