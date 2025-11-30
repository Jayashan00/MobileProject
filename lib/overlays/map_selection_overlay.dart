import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

class MapSelectionOverlay extends StatefulWidget {
  final MyGame game;

  const MapSelectionOverlay({super.key, required this.game});

  @override
  State<MapSelectionOverlay> createState() => _MapSelectionOverlayState();
}

class _MapSelectionOverlayState extends State<MapSelectionOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(230),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'MISSION CONTROL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Wallet Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: Colors.yellow, size: 28),
              const SizedBox(width: 10),
              Text(
                'CREDITS: ${widget.game.wallet}',
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Map List
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items per row
                childAspectRatio: 0.8,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: widget.game.maps.length,
              itemBuilder: (context, index) {
                final map = widget.game.maps[index];
                final bool isUnlocked = widget.game.unlockedMapIndices.contains(index);
                final bool isSelected = widget.game.currentMapIndex == index;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    border: isSelected
                        ? Border.all(color: Colors.green, width: 3)
                        : Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // Preview Image (Placeholder icon or asset)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                            image: index == 0
                                ? null // No image for default space
                                : DecorationImage(
                                    image: AssetImage('assets/images/${map.asset}'),
                                    fit: BoxFit.cover,
                                    colorFilter: isUnlocked
                                      ? null
                                      : const ColorFilter.mode(Colors.black54, BlendMode.darken),
                                  ),
                          ),
                          child: index == 0
                             ? const Center(child: Icon(Icons.star, color: Colors.white, size: 50))
                             : null,
                        ),
                      ),

                      // Name
                      Text(
                        map.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),

                      // Button logic
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("SELECTED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )
                      else if (isUnlocked)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              widget.game.selectMap(index);
                            });
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text("SELECT", style: TextStyle(color: Colors.white)),
                        )
                      else
                        ElevatedButton(
                          onPressed: widget.game.wallet >= map.cost
                              ? () {
                                  setState(() {
                                    bool success = widget.game.buyMap(index);
                                    if(!success) {
                                      // Optional: Show error
                                    }
                                  });
                                }
                              : null, // Disable if not enough money
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            disabledBackgroundColor: Colors.grey[800],
                          ),
                          child: Text(
                            "BUY: ${map.cost}",
                            style: TextStyle(
                              color: widget.game.wallet >= map.cost ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          // Back Button
          ElevatedButton(
            onPressed: () {
              widget.game.audioManager.playSound('click');
              widget.game.overlays.remove('MapSelection');
              widget.game.overlays.add('Title');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('BACK TO MENU',
                style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}