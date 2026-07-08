import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'battle_game.dart';
import 'hud_overlay.dart';

class GameBootstrap extends StatelessWidget {
  const GameBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final game = BattleGame();

    return Scaffold(
      body: GameWidget<BattleGame>(
        game: game,
        overlayBuilderMap: {
          'HUD': (context, game) => const SizedBox.shrink(),
        },
      ),
    );
  }
}
