import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../transitions/menu_transitions.dart';
import 'options_menu.dart';
import 'help_menu.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _navigateToOptionsMenu(BuildContext context) {
    Navigator.push(
      context,
      CoordinatedSlideTransition(
        enterPage: OptionsMenu(onBack: () => Navigator.pop(context)),
        slideFromLeft: true,
      ),
    );
  }

  void _navigateToHelpMenu(BuildContext context) {
    Navigator.push(
      context,
      CoordinatedSlideTransition(
        enterPage: HelpMenu(onBack: () => Navigator.pop(context)),
        slideFromLeft: false,
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Close"),
          content: const Text("Are you sure you want to close the app?"),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildMenuButtons(double buttonHeight, BuildContext context) {
    final List<String> buttonTitles = ['Quick game', 'Setup game', 'Options', 'Help', 'Close'];
    final List<VoidCallback> actions = [
          () {}, // Quick game action
          () {}, // Setup game action
          () => _navigateToOptionsMenu(context),
          () => _navigateToHelpMenu(context),
          () => _showExitConfirmationDialog(context),
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40),
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
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.04),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildMenuButtons(buttonHeight, context),
                  ),
                ),
              ),
              const Spacer()
            ],
          ),
        ],
      ),
    );
  }
}