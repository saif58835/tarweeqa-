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
  // **مهم جدًا:** غير هذا الرابط حسب مكان تشغيل سيرفرك
  final TextEditingController serverController = TextEditingController(text: 'http://localhost:3000'); 

  final NetworkService networkService = NetworkService();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    roomController.dispose();
    serverController.dispose();
    super.dispose();
  }

  void handleJoin() async {
    final name = nameController.text.trim();
    final roomId = roomController.text.trim();
    final serverUrl = serverController.text.trim();

    if (name.isEmpty || roomId.isEmpty || serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول!')),
      );
      return;
    }

    setState(() => isLoading = true);

    // 1. الاتصال بالخادم
    networkService.connectToServer(serverUrl);
    // 2. الانضمام للغرفة
    networkService.joinRoom(roomId, name);

    // ننتظر قليلاً لتأكيد الاتصال وسماع الـ update_players الأول
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => isLoading = false);

    // 3. الذهاب لشاشة اللعبة مع تمرير بيانات الشبكة
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          networkService: networkService,
          isSinglePlayer: false, // هذه لعبة جماعية متعددة
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع لأي تغيير في قائمة اللاعبين لتحديث الواجهة تلقائياً
    networkService.addListener(() {
      if (mounted) setState(() {});
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F1020),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Warrior Sword Multiplayer',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'انضم إلى المعركة مع أصدقائك',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                
                _buildField(nameController, 'اسمك في المعركة'),
                const SizedBox(height: 14),
                _buildField(roomController, 'كود الغرفة (شاركه مع أصدقائك)'),
                const SizedBox(height: 14),
                _buildField(serverController, 'رابط الخادم (IP)'),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isLoading ? null : handleJoin,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('دخول ساحة القتال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                // عرض قائمة الأصدقاء الموجودين في الغرفة
                const SizedBox(height: 30),
                const Text("اللاعبون في الغرفة:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: networkService.playersInRoom.isEmpty
                      ? const Text("لا يوجد لاعبون آخرون بعد...", style: TextStyle(color: Colors.white38))
                      : Column(
                          children: networkService.playersInRoom.map((player) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.cyanAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text("• ${player['name']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
