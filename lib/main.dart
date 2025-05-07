// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/menu/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const ChockABlock());
}

class ChockABlock extends StatelessWidget {
  const ChockABlock({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chock-A-Block',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainMenuScreen(),
    );
  }
}