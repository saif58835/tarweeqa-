import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'battle_game.dart';
import '../network/network_service.dart';

class GameScreen extends StatelessWidget {
  final NetworkService networkService;

  const GameScreen({super.key, required this.networkService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: BattleGame(networkService: networkService),
      ),
    );
  }
}
