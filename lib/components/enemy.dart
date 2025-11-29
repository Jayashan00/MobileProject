import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Enemy extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {

  // Movement variables
  late double _speed; // Changed to late so we can set it in constructor
  double _time = 0;
  final double _initialX;

  // Shooting variables
  late Timer _shootTimer;
  final Random _random = Random();

  // Health
  int _hp = 2;

  // NEW: Accept speedMultiplier
  Enemy({required Vector2 position, double speedMultiplier = 1.0})
      : _initialX = position.x,
        super(position: position, size: Vector2.all(180), anchor: Anchor.center) {
    // Base speed is 150, multiplied by difficulty
    _speed = 150 * speedMultiplier;
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('enemy.png');

    angle = pi;

    add(RectangleHitbox());

    _shootTimer = Timer(
      1.5 + _random.nextDouble() * 1.5,
      onTick: _shoot,
      repeat: true,
    );
    _shootTimer.start();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _shootTimer.update(dt);
    _time += dt;

    // 1. Move Down
    position.y += _speed * dt;

    // 2. Sine Wave Movement
    position.x = _initialX + sin(_time * 3) * 100;

    // 3. Cleanup if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void _shoot() {
    if (position.y < 0 || position.y > game.size.y) return;

    game.audioManager.playSound('laser');

    game.add(EnemyLaser(position: position + Vector2(0, size.y / 2)));
  }

  void takeDamage() {
    game.audioManager.playSound('hit');
    _hp--;

    add(ColorEffect(
      const Color(0xFFFFFFFF),
      EffectController(duration: 0.1, alternate: true),
    ));

    if (_hp <= 0) {
      _destroy();
    }
  }

  void _destroy() {
    removeFromParent();
    game.incrementScore(5);

    game.add(Explosion(
      position: position,
      explosionSize: size.x,
      explosionType: ExplosionType.fire,
    ));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Laser) {
      other.removeFromParent();
      takeDamage();
    }
  }
}