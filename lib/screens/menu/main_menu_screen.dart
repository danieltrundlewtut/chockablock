import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../transitions/menu_transitions.dart';
import '../../helpers/puzzle_read_write.dart';
import '../../widgets/misc/loading_widget.dart';
import '../game_screen_classic.dart';
import 'options_menu.dart';
import 'help_menu.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Future<void> _startQuickGame(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(message: 'Loading...');
      },
    );

    // Simulate loading time (remove in production)
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GameScreen()),
      );
    }
  }

  void _showSeedInputDialog(BuildContext context) {
    final TextEditingController seedController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter Puzzle Seed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: seedController,
                decoration: const InputDecoration(
                  labelText: 'Seed Number',
                  hintText: 'Enter the puzzle seed',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final seedText = seedController.text.trim();
                if (seedText.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  _loadPuzzleBySeed(context, int.parse(seedText));
                }
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPuzzleBySeed(BuildContext context, int seed) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: 'Loading puzzle with seed $seed...');
      },
    );

    try {
      // Get a puzzle with the specified seed
      final puzzle = await PuzzleManager.getPuzzleBySeed(seed);

      if (puzzle == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No puzzle found with seed $seed'))
          );
        }
        return;
      }

      // Get difficulty from the puzzle
      final difficulty = puzzle['calculatedDifficulty'] ?? 'Medium';
      final difficultyEnum = PuzzleManager.difficultyFromString(difficulty);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              difficulty: difficultyEnum,
              savedPuzzleData: puzzle,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error loading puzzle: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading puzzle: $e'))
        );
      }
    }
  }

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
    final List<String> buttonTitles = [
      'Quick game',
      'Load puzzle',
      'Options',
      'Help',
      'Close'
    ];
    final List<VoidCallback> actions = [
          () => _startQuickGame(context),
          () => _showSeedInputDialog(context),
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