import 'dart:async';

import 'package:cosmic_havoc/my_game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

class PauseButton extends SpriteComponent
    with HasGameReference<MyGame>, TapCallbacks {

  PauseButton() : super(
    size: Vector2.all(50),
    anchor: Anchor.topRight,
    priority: 20 // High priority to be on top of everything
  );

  @override
  FutureOr<void> onLoad() async {
    // Make sure you have 'pause_button.png' in assets/images/
    sprite = await game.loadSprite('pause_button.png');

    // Position it at the top right with some padding
    position = Vector2(game.size.x - 20, 50);

    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 1. Check if the game is already paused or over
    if (game.paused || game.overlays.isActive('GameOver')) return;

    game.audioManager.playSound('click');

    // 2. Show the Pause Overlay
    game.overlays.add('Pause');

    // 3. Pause the Game Engine (stops update loop)
    game.pauseEngine();

    super.onTapDown(event);
  }
}