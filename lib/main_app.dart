import 'package:flutter/material.dart';
import 'ui/host_join_screen.dart';

void main() {
  runApp(const MiniMissionApp());
}

class MiniMissionApp extends StatelessWidget {
  const MiniMissionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini Mission',
      theme: ThemeData.dark(),
      home: const HostJoinScreen(),
    );
  }
}
