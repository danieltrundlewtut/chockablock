import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 40), // Adjust top spacing
              child: Center(
                child: Text(
                  'Chock-A-Block',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerRight, // Aligns the column of buttons to the right
              child: Padding(
                padding: const EdgeInsets.only(right: 20), // Adjust right spacing
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Prevents extra space
                  crossAxisAlignment: CrossAxisAlignment.end, // Aligns buttons to the right
                  children: _buildMenuButtons(buttonHeight, context),
                ),
              ),
            ),
            const Spacer()
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuButtons(double buttonHeight, BuildContext context) {
    final List<String> buttonTitles = ['Quick game', 'Setup game', 'Options', 'Help', 'Close'];
    final List<VoidCallback?> actions = [
          () {}, // Quick game action
          () {}, // Setup game action
          () {}, // Options action
          () {}, // Help action
          () => SystemNavigator.pop(), // Close app
    ];

    return List.generate(buttonTitles.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: IntrinsicWidth(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: actions[index],
              child: Text(buttonTitles[index], style: const TextStyle(fontSize: 20)),
            ),
          ),
        ),
      );
    });
  }
}
