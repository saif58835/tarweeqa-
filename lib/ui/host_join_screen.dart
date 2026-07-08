import 'package:flutter/material.dart';
import '../network/network_service.dart';
import '../game/game_screen.dart';

class HostJoinScreen extends StatefulWidget {
  const HostJoinScreen({super.key});

  @override
  State<HostJoinScreen> createState() => _HostJoinScreenState();
}

class _HostJoinScreenState extends State<HostJoinScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController ipController = TextEditingController(text: '192.168.1.1');
  final TextEditingController portController = TextEditingController(text: '4040');

  final NetworkService networkService = NetworkService();

  bool isLoading = false;
  String mode = 'host';

  @override
  void dispose() {
    nameController.dispose();
    roomController.dispose();
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  Future<void> handleAction() async {
    final name = nameController.text.trim();
    final roomId = roomController.text.trim();
    final ip = ipController.text.trim();
    final port = int.tryParse(portController.text.trim()) ?? 4040;

    if (name.isEmpty || roomId.isEmpty) return;

    setState(() => isLoading = true);

    try {
      if (mode == 'host') {
        await networkService.host(name: name, roomId: roomId, port: port);
      } else {
        await networkService.join(
          name: name,
          roomId: roomId,
          ip: ip,
          port: port,
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(networkService: networkService),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1020),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mini Mission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildField(nameController, 'Your name'),
                const SizedBox(height: 12),
                _buildField(roomController, 'Room ID'),
                const SizedBox(height: 12),
                _buildField(ipController, 'Host IP'),
                const SizedBox(height: 12),
                _buildField(portController, 'Port', keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _modeButton('host', 'Host'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modeButton('join', 'Join'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleAction,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(mode == 'host' ? 'Create Room' : 'Join Room'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _modeButton(String value, String text) {
    final selected = mode == value;
    return OutlinedButton(
      onPressed: () => setState(() => mode = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10,
        foregroundColor: Colors.white,
        side: BorderSide(color: selected ? Colors.cyanAccent : Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text),
    );
  }
}
