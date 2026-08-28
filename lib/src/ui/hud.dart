import 'package:flutter/material.dart';

import '../actors/player.dart';

class Hud extends StatelessWidget {
  final double timeLeft;
  final double elapsed;
  final List<Player> players;
  const Hud({
    super.key,
    required this.timeLeft,
    required this.elapsed,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: timeLeft < 10 ? Colors.redAccent : Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${(timeLeft ~/ 60).toString().padLeft(2,'0')}:${(timeLeft % 60).toStringAsFixed(0).padLeft(2,'0')}',
                        style: TextStyle(
                          color: timeLeft < 10 ? Colors.redAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${players.where((p) => p.isAlive).length} VIVOS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: players.map((p) {
                final alive = p.isAlive;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: alive ? 1 : 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: p.isHuman ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: alive ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.damage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (!alive)
                          const Text('💀', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
