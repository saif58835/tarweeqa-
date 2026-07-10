import 'package:flutter/material.dart';
import '../network/network_service.dart';
import '../game/game_screen.dart';

class HostJoinScreen extends StatefulWidget {
  const HostJoinScreen({super.key});

  @override
  State<HostJoinScreen> createState() => _HostJoinScreenState();
}

class _HostJoinScreenState extends State<HostJoinScreen> {

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController roomController =
      TextEditingController();

  final TextEditingController serverController =
      TextEditingController(
        text: 'http://YOUR_SERVER_IP:3000',
      );


  final NetworkService networkService = NetworkService();

  bool isLoading = false;


  @override
  void initState() {
    super.initState();

    networkService.addListener(_updatePlayers);
  }


  void _updatePlayers() {

    if (mounted) {
      setState(() {});
    }

  }



  @override
  void dispose() {

    networkService.removeListener(_updatePlayers);

    nameController.dispose();
    roomController.dispose();
    serverController.dispose();

    networkService.dispose();

    super.dispose();
  }



  Future<void> handleJoin() async {

    final name = nameController.text.trim();
    final roomId = roomController.text.trim();
    final serverUrl = serverController.text.trim();


    if (name.isEmpty ||
        roomId.isEmpty ||
        serverUrl.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول!'),
        ),
      );

      return;
    }



    setState(() {
      isLoading = true;
    });



    networkService.connectToServer(serverUrl);


    await Future.delayed(
      const Duration(milliseconds: 500),
    );


    networkService.joinRoom(
      roomId,
      name,
    );



    await Future.delayed(
      const Duration(seconds: 1),
    );


    if (!mounted) return;


    setState(() {
      isLoading = false;
    });



    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          networkService: networkService,
          isSinglePlayer: false,
        ),
      ),
    );

  }




  @override
  Widget build(BuildContext context) {

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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),


                const SizedBox(height: 10),


                const Text(
                  'انضم إلى المعركة مع أصدقائك',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),


                const SizedBox(height: 40),



                _buildField(
                  nameController,
                  'اسمك في المعركة',
                ),


                const SizedBox(height: 14),


                _buildField(
                  roomController,
                  'كود الغرفة',
                ),


                const SizedBox(height: 14),


                _buildField(
                  serverController,
                  'رابط الخادم',
                ),



                const SizedBox(height: 30),



                SizedBox(

                  width: double.infinity,

                  height: 54,


                  child: ElevatedButton(

                    onPressed:
                        isLoading ? null : handleJoin,


                    style:
                        ElevatedButton.styleFrom(

                      backgroundColor:
                          Colors.cyanAccent,

                      foregroundColor:
                          Colors.black,

                    ),


                    child: isLoading

                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )

                        : const Text(
                            'دخول ساحة القتال',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                  ),

                ),



                const SizedBox(height: 30),



                const Text(
                  "اللاعبون في الغرفة:",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),



                const SizedBox(height: 10),



                Text(
                  networkService.playersInRoom.isEmpty
                      ? "لا يوجد لاعبون آخرون بعد..."
                      : networkService.playersInRoom
                          .map((p) => p['name'])
                          .join("\n"),

                  style: const TextStyle(
                    color: Colors.white,
                  ),

                  textAlign: TextAlign.center,
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
      String hint,
      ) {

    return TextField(

      controller: controller,

      style: const TextStyle(
        color: Colors.white,
      ),


      decoration: InputDecoration(

        hintText: hint,

        hintStyle:
            const TextStyle(
          color: Colors.white54,
        ),


        filled: true,

        fillColor:
            Colors.white10,


        border:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(14),

          borderSide:
              BorderSide.none,

        ),

      ),

    );

  }

}
