import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/asteroid.dart';
import 'package:cosmic_havoc/components/audio_manager.dart';
import 'package:cosmic_havoc/components/boss.dart';
import 'package:cosmic_havoc/components/enemy.dart';
import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/health_bar.dart';
import 'package:cosmic_havoc/components/pause_button.dart';
import 'package:cosmic_havoc/components/pickup.dart';
import 'package:cosmic_havoc/components/player.dart';
import 'package:cosmic_havoc/components/shoot_button.dart';
import 'package:cosmic_havoc/components/star.dart';
import 'package:cosmic_havoc/components/driver_hud.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart'; // Import Parallax
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Class to hold Map Information
class MapData {
  final String name;
  final String asset;
  final int cost;

  MapData({required this.name, required this.asset, required this.cost});
}

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
  bool _bossSpawned = false;

  // Upgrade Variables
  int wallet = 0;
  int healthLevel = 0;
  int speedLevel = 0;
  int fireRateLevel = 0;

  // Driver Selection
  int selectedDriver = 0;
  late DriverHud driverHud;

  // --- NEW: Map System Variables ---
  final List<MapData> maps = [
    MapData(name: 'Deep Space', asset: 'default', cost: 0), // Index 0: Default
    MapData(name: 'Nebula', asset: 'map_1.png', cost: 500),
    MapData(name: 'Red Galaxy', asset: 'map_2.png', cost: 1000),
    MapData(name: 'Void Base', asset: 'map_3.png', cost: 2000),
  ];
  List<int> unlockedMapIndices = [0]; // Default map is always unlocked
  int currentMapIndex = 0;
  ParallaxComponent? _currentBackground;
  // -------------------------------

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

    await loadData();

    // Initialize Background based on loaded data
    _updateBackground();
    _createStars(); // Stars are drawn on top of the background

    return super.onLoad();
  }

  // Load all data including upgrades and maps
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
    wallet = prefs.getInt('wallet') ?? 0;
    healthLevel = prefs.getInt('healthLevel') ?? 0;
    speedLevel = prefs.getInt('speedLevel') ?? 0;
    fireRateLevel = prefs.getInt('fireRateLevel') ?? 0;
    selectedDriver = prefs.getInt('selectedDriver') ?? 0;

    // LOAD MAPS
    currentMapIndex = prefs.getInt('currentMapIndex') ?? 0;
    String? unlockedString = prefs.getString('unlockedMaps');
    if (unlockedString != null && unlockedString.isNotEmpty) {
      unlockedMapIndices =
          unlockedString.split(',').map((e) => int.parse(e)).toList();
    }
  }

  // Save all data including upgrades and maps
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_score > highScore) {
      highScore = _score;
      await prefs.setInt('highScore', highScore);
    }
    await prefs.setInt('wallet', wallet);
    await prefs.setInt('healthLevel', healthLevel);
    await prefs.setInt('speedLevel', speedLevel);
    await prefs.setInt('fireRateLevel', fireRateLevel);
    await prefs.setInt('selectedDriver', selectedDriver);

    // SAVE MAPS
    await prefs.setInt('currentMapIndex', currentMapIndex);
    await prefs.setString('unlockedMaps', unlockedMapIndices.join(','));
  }

  // --- Logic to Buy a Map ---
  bool buyMap(int index) {
    if (index < 0 || index >= maps.length) return false;
    if (unlockedMapIndices.contains(index)) return true; // Already owned

    int cost = maps[index].cost;
    if (wallet >= cost) {
      wallet -= cost;
      unlockedMapIndices.add(index);
      saveData();
      audioManager.playSound('collect');
      return true;
    }
    return false;
  }

  // --- Logic to Select a Map ---
  void selectMap(int index) {
    if (unlockedMapIndices.contains(index)) {
      currentMapIndex = index;
      _updateBackground(); // Change the visual immediately
      saveData();
      audioManager.playSound('click');
    }
  }

  // --- Helper to update the visual background ---
  void _updateBackground() async {
    // 1. Remove existing background if present
    if (_currentBackground != null) {
      remove(_currentBackground!);
      _currentBackground = null;
    }

    // 2. If it's the default map (index 0), we use the black background + stars only
    if (currentMapIndex == 0) {
      return;
    }

    // 3. Load Parallax for other maps
    String asset = maps[currentMapIndex].asset;
    _currentBackground = await loadParallaxComponent(
      [ParallaxImageData(asset)],
      baseVelocity: Vector2(0, 50), // Slowly scroll down
      velocityMultiplierDelta: Vector2(1, 1),
      repeat: ImageRepeat.repeat,
    );

    // Make sure it's behind everything (-100 priority)
    _currentBackground!.priority = -100;
    add(_currentBackground!);
  }

  void buyUpgrade(String type) {
    int cost = 0;

    if (type == 'health' && healthLevel < 5) {
      cost = 100 * (healthLevel + 1);
      if (wallet >= cost) {
        wallet -= cost;
        healthLevel++;
        audioManager.playSound('collect');
      }
    } else if (type == 'speed' && speedLevel < 5) {
      cost = 100 * (speedLevel + 1);
      if (wallet >= cost) {
        wallet -= cost;
        speedLevel++;
        audioManager.playSound('collect');
      }
    } else if (type == 'fireRate' && fireRateLevel < 5) {
      cost = 100 * (fireRateLevel + 1);
      if (wallet >= cost) {
        wallet -= cost;
        fireRateLevel++;
        audioManager.playSound('collect');
      }
    }
    saveData();
  }

  void startGame() async {
    audioManager.playMusic();
    _bossSpawned = false;

    await _createJoystick();
    await _createPlayer();
    _createShootButton();
    _createAsteroidSpawner();
    _createEnemySpawner();
    _createPickupSpawner();
    _createScoreDisplay();

    driverHud = DriverHud();
    add(driverHud);

    add(HealthBar());
    add(PauseButton());
  }

  void shakeWorld({double intensity = 10, double duration = 0.05}) {
    if (camera.viewfinder.children.whereType<MoveEffect>().isNotEmpty) return;

    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(intensity, intensity),
        EffectController(
          duration: duration,
          alternate: true,
          repeatCount: 4,
        ),
      ),
    );
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

    if (_score >= 200 && !_bossSpawned) {
      _spawnBoss();
    }
  }

  void _spawnBoss() {
    _bossSpawned = true;
    _enemySpawner.timer.stop();
    add(Boss());
  }

  void bossDefeated() {
    _enemySpawner.timer.start();
  }

  void _createStars() {
    // Ensure stars are always behind game objects but in front of background
    // If background is -100, stars can be -10
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() async {
    wallet += _score;
    await saveData();
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid ||
          component is Pickup ||
          component is HealthBar ||
          component is Enemy ||
          component is EnemyLaser ||
          component is PauseButton ||
          component is Boss ||
          component is DriverHud) {
        remove(component);
      }
    });

    _bossSpawned = false;

    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();
    _enemySpawner.timer.start();

    camera.viewfinder.children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
    camera.viewfinder.position = Vector2.zero();

    _score = 0;
    _scoreDisplay.text = '0';

    _createPlayer();

    driverHud = DriverHud();
    add(driverHud);

    add(HealthBar());
    add(PauseButton());

    resumeEngine();
  }

  void quitGame() {
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star && component is! ParallaxComponent) {
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