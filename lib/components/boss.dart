import 'dart:async';
import 'dart:math';

import 'package:cosmic_havoc/components/enemy_laser.dart';
import 'package:cosmic_havoc/components/explosion.dart';
import 'package:cosmic_havoc/components/laser.dart';
import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class Boss extends SpriteComponent
    with HasGameReference<MyGame>, CollisionCallbacks {

  int _hp = 50; // Boss takes 50 hits to destroy
  final double _speed = 100;
  bool _isMovingRight = true;
  late Timer _shootTimer;

  // Boss is large (250x250)
  Boss() : super(size: Vector2.all(250), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    // Load the specific boss image
    sprite = await game.loadSprite('boss.png');

    // Rotate to face down (if your image points up)
    angle = pi;

    // Start slightly above the screen
    position = Vector2(game.size.x / 2, -150);

    add(RectangleHitbox());

    // Entrance Animation: Fly down to y=150
    add(MoveToEffect(
      Vector2(game.size.x / 2, 150),
      EffectController(duration: 2, curve: Curves.easeOut),
    ));

    // Shoot 3 lasers every 1.5 seconds
    _shootTimer = Timer(1.5, onTick: _tripleShot, repeat: true);
    _shootTimer.start();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _shootTimer.update(dt);

    // Logic: Only move side-to-side AFTER entering the screen (y >= 150)
    if (position.y >= 150) {
      if (_isMovingRight) {
        position.x += _speed * dt;
        // Turn left if hitting right edge
        if (position.x > game.size.x - size.x / 2) {
          _isMovingRight = false;
        }
      } else {
        position.x -= _speed * dt;
        // Turn right if hitting left edge
        if (position.x < size.x / 2) {
          _isMovingRight = true;
        }
      }
    }
  }

  void _tripleShot() {
    // Only shoot if visible
    if (position.y < 0) return;

    game.audioManager.playSound('laser');

    // Shoot 3 lasers: Left (-40), Center (0), Right (+40)
    // Adjust y spawn point based on rotation (size.y/2)
    game.add(EnemyLaser(position: position + Vector2(-40, size.y / 2)));
    game.add(EnemyLaser(position: position + Vector2(0, size.y / 2)));
    game.add(EnemyLaser(position: position + Vector2(40, size.y / 2)));
  }

  void takeDamage() {
    _hp--;
    game.audioManager.playSound('hit');

    // Visual feedback: Flash White
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
    game.incrementScore(500); // 500 points reward

    // Play big explosion sound if you have it, otherwise reuse explode1
    game.audioManager.playSound('explode1');

    // Create a massive explosion effect
    game.add(Explosion(
      position: position,
      explosionSize: size.x,
      explosionType: ExplosionType.fire,
    ));

    // Notify game logic
    game.bossDefeated();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Laser) {
      other.removeFromParent(); // Destroy player laser
      takeDamage();
    }
  }
}