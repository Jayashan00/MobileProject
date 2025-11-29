import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class TitleOverlay extends StatefulWidget {
  final MyGame game;

  const TitleOverlay({super.key, required this.game});

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

class _TitleOverlayState extends State<TitleOverlay> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String playerColor =
        widget.game.playerColors[widget.game.playerColorIndex];

    return AnimatedOpacity(
      onEnd: () {
        if (_opacity == 0.0) {
          widget.game.overlays.remove('Title');
        }
      },
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            const SizedBox(height: 60),
            SizedBox(
              width: 270,
              child: Image.asset('assets/images/title.png'),
            ),

            // NEW: Display High Score on Title Screen
            const SizedBox(height: 20),
            Text(
              'HIGH SCORE: ${widget.game.highScore}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 4, color: Colors.blue, offset: Offset(0, 0))
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Character Selector Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    widget.game.audioManager.playSound('click');
                    setState(() {
                      widget.game.playerColorIndex--;
                      if (widget.game.playerColorIndex < 0) {
                        widget.game.playerColorIndex =
                            widget.game.playerColors.length - 1;
                      }
                    });
                  },
                  child: Transform.flip(
                    flipX: true,
                    child: SizedBox(
                      width: 30,
                      child: Image.asset('assets/images/arrow_button.png'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SizedBox(
                    width: 100,
                    child: Image.asset(
                      'assets/images/player_${playerColor}_off.png',
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.game.audioManager.playSound('click');
                    setState(() {
                      widget.game.playerColorIndex++;
                      if (widget.game.playerColorIndex ==
                          widget.game.playerColors.length) {
                        widget.game.playerColorIndex = 0;
                      }
                    });
                  },
                  child: SizedBox(
                    width: 30,
                    child: Image.asset('assets/images/arrow_button.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                widget.game.audioManager.playSound('start');
                widget.game.startGame();
                setState(() {
                  _opacity = 0.0;
                });
              },
              child: SizedBox(
                width: 200,
                child: Image.asset('assets/images/start_button.png'),
              ),
            ),

            // Audio Controls (Bottom Right)
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.game.audioManager.toggleMusic();
                          });
                        },
                        icon: Icon(
                          widget.game.audioManager.musicEnabled
                              ? Icons.music_note_rounded
                              : Icons.music_off_rounded,
                          color: widget.game.audioManager.musicEnabled
                              ? Colors.white
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.game.audioManager.toggleSounds();
                          });
                        },
                        icon: Icon(
                          widget.game.audioManager.soundsEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: widget.game.audioManager.soundsEnabled
                              ? Colors.white
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}