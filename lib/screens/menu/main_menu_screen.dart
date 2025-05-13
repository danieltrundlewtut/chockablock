import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/puzzle_read_write.dart';
import '../../transitions/menu_transitions.dart';
import '../../helpers/puzzle_loader.dart';
import '../../widgets/misc/loading_widget.dart';
import '../../widgets/subMenus/setup_menu_widget.dart';
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

  Future<void> _loadSavedPuzzle(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(message: 'Loading puzzle...');
      },
    );

    try {
      // Get a random puzzle
      final puzzle = await PuzzleLoader.getRandomPuzzle();

      if (puzzle == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No puzzles found. Create some in dev mode!'))
          );
        }
        return;
      }

      // Get the difficulty from the puzzle
      final difficultyStr = puzzle['calculatedDifficulty'] ?? puzzle['difficulty'] ?? 'medium';
      final difficulty = PuzzleLoader.difficultyFromString(difficultyStr);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              difficulty: difficulty,
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

// Updated main menu methods using PuzzleManager
  void _choosePuzzleDifficulty(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choose Difficulty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _difficultyButton(
                dialogContext,
                'Easy',
                Colors.green,
                    () => _loadPuzzleWithDifficulty(context, 'Easy'),
              ),
              const SizedBox(height: 12),
              _difficultyButton(
                dialogContext,
                'Medium',
                Colors.orange,
                    () => _loadPuzzleWithDifficulty(context, 'Medium'),
              ),
              const SizedBox(height: 12),
              _difficultyButton(
                dialogContext,
                'Hard',
                Colors.red,
                    () => _loadPuzzleWithDifficulty(context, 'Hard'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPuzzleWithDifficulty(BuildContext context, String difficulty) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoadingDialog(message: 'Loading $difficulty puzzle...');
      },
    );

    try {
      // Get a random puzzle with the specified difficulty
      final puzzle = await PuzzleManager.getRandomPuzzle(difficulty: difficulty);

      if (puzzle == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No $difficulty puzzles found. Create some in dev mode!'))
          );
        }
        return;
      }

      // Get difficulty enum from the calculatedDifficulty
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
  Widget _difficultyButton(
      BuildContext context,
      String label,
      Color color,
      VoidCallback onPressed
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          onPressed();
        },
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  void _showSetupGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SetupGameMenu(
          onBack: () => Navigator.of(context).pop(),
        );
      },
    );
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
      'Setup game',
      'Options',
      'Help',
      'Close'
    ];
    final List<VoidCallback> actions = [
          () => _startQuickGame(context),
          () => _choosePuzzleDifficulty(context),
          () => _showSetupGameDialog(context),
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