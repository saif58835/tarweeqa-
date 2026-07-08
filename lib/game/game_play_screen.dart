import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../network/network_service.dart';
import 'battle_game.dart';

class BattleScreen extends StatelessWidget {
  final NetworkService networkService;

  const BattleScreen({
    super.key,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: BattleGame(),
      ),
    );
  }
}
