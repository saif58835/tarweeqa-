import 'package:flutter/material.dart';
// في المستقبل عندما تنشئ هذه الملفات، ستحتاج لإزالة التعليقات وتفعيل هذه الأسطر:
// import 'ui/host_join_screen.dart';
// import 'ui/single_player_screen.dart';

void main() {
  runApp(const BattleDuoApp());
}

class BattleDuoApp extends StatelessWidget {
  const BattleDuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battle Duo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1020), Color(0xFF1D1F3A), Color(0xFF2A1B5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الشعار
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.sports_esports, size: 72, color: Colors.cyanAccent),
                        SizedBox(height: 14),
                        Text(
                          'Battle Duo',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'لعبة 1v1 ضد الروبوت أو الأصدقاء',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // زر اللعب الفردي (ضد الروبوت) - جديد
                  _MenuButton(
                    title: 'ضد الروبوت',
                    subtitle: 'تحدي الذكاء الاصطناعي',
                    icon: Icons.smart_toy,
                    onTap: () {
                      // TODO: استبدل هذه بواجهة SinglePlayerScreen الحقيقية
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'ضد الروبوت')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 14),

                  // زر إنشاء غرفة (للأصدقاء)
                  _MenuButton(
                    title: 'إنشاء غرفة',
                    subtitle: 'استضف أصدقاءك',
                    icon: Icons.wifi_tethering,
                    onTap: () {
                      // TODO: استبدل هذه بـ HostJoinScreen مع mode: 'host'
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'إنشاء غرفة')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // زر الانضمام (للأصدقاء)
                  _MenuButton(
                    title: 'الانضمام',
                    subtitle: 'انضم إلى صديقك',
                    icon: Icons.wifi,
                    onTap: () {
                      // TODO: استبدل هذه بـ HostJoinScreen مع mode: 'join'
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'الانضمام')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// زر القائمة المخصص
class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.10),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.cyanAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// شاشة مؤقتة (سنقوم بحذفها لاحقاً)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text(
          'هنا سيتم وضع شاشة اللعب الفعلية (ضد الروبوت أو مع الأصدقاء)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
