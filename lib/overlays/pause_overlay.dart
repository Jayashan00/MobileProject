import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  final MyGame game;

  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(150), // Semi-transparent black background
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PAUSED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 30),

          // RESUME BUTTON
          TextButton(
            onPressed: () {
              game.audioManager.playSound('click');

              // Remove the overlay
              game.overlays.remove('Pause');

              // Resume the game engine
              game.resumeEngine();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'RESUME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // QUIT BUTTON
          TextButton(
            onPressed: () {
              game.audioManager.playSound('click');

              game.overlays.remove('Pause');
              game.quitGame();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'QUIT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}