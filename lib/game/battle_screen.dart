import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../network/network_service.dart';
import 'battle_game.dart';

class GameScreen extends StatelessWidget {
  final NetworkService networkService;

  const GameScreen({
    super.key,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    final game = BattleGame();

    return Scaffold(
      body: GameWidget(
        game: game,
      ),
    );
  }
}
