import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

// Changed to a widget to be used inside Main Menu
class MapSelectionWidget extends StatefulWidget {
  final MyGame game;

  const MapSelectionWidget({super.key, required this.game});

  @override
  State<MapSelectionWidget> createState() => _MapSelectionWidgetState();
}
//map Selection Class
class _MapSelectionWidgetState extends State<MapSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'SECTOR MAPS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: widget.game.maps.length,
            itemBuilder: (context, index) {
              final map = widget.game.maps[index];
              final bool isUnlocked =
                  widget.game.unlockedMapIndices.contains(index);
              final bool isSelected = widget.game.currentMapIndex == index;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  border: isSelected
                      ? Border.all(color: Colors.greenAccent, width: 2)
                      : Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          image: index == 0
                              ? null
                              : DecorationImage(
                                  image:
                                      AssetImage('assets/images/${map.asset}'),
                                  fit: BoxFit.cover,
                                  colorFilter: isUnlocked
                                      ? null
                                      : const ColorFilter.mode(
                                          Colors.black87, BlendMode.darken),
                                ),
                        ),
                        child: index == 0
                            ? const Center(
                                child: Icon(Icons.public,
                                    color: Colors.blue, size: 40))
                            : (!isUnlocked
                                ? const Center(
                                    child: Icon(Icons.lock,
                                        color: Colors.white54, size: 30))
                                : null),
                      ),
                    ),
                    Text(
                      map.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (isSelected)
                      const Text("DEPLOYING",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))
                    else if (isUnlocked)
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              widget.game.selectMap(index);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey),
                          child: const Text("SELECT",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      )
                    else
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: widget.game.wallet >= map.cost
                              ? () {
                                  setState(() {
                                    widget.game.buyMap(index);
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text("BUY ${map.cost}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}