import 'package:flutter/material.dart';
import '../enums/game_difficulty_enum.dart';
import '../enums/game_mode_enum.dart';
import '../../widgets/loading_widget.dart';
import '../screens/game_screen_classic.dart';

class SetupGameMenu extends StatefulWidget {
  final Function onBack;

  const SetupGameMenu({super.key, required this.onBack});

  @override
  State<SetupGameMenu> createState() => _SetupGameMenuState();
}

class _SetupGameMenuState extends State<SetupGameMenu> {
  String _selectedMode = 'Classic';
  String _selectedDifficulty = 'Medium';

  Future<void> _startGame(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoadingDialog(message: 'Loading...');
      },
    );

    // Simulate loading time (remove in production)
    await Future.delayed(const Duration(milliseconds: 500));

    // Convert difficulty selection to enum
    GameDifficulty difficulty;
    switch (_selectedDifficulty) {
      case 'Medium':
        difficulty = GameDifficulty.medium;
        break;
      case 'Hard':
        difficulty = GameDifficulty.hard;
        break;
      case 'Easy':
      default:
        difficulty = GameDifficulty.easy;
        break;
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // Pop loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            difficulty: difficulty,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = 150;
    final availableWidth = MediaQuery.of(context).size.width * 0.6 - 40.0; // Dialog width - padding
    final buttonSpacing = (availableWidth - (buttonWidth * 3)) / 4; // Divide remaining space evenly

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button positioned to the right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left-aligned title
                const Text(
                  'Setup new game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Close button positioned to the right
                GestureDetector(
                  onTap: () => widget.onBack(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            const Text(
              'Game mode',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: buttonSpacing),
              child: Row(
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildModeButton('Classic', true)
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildModeButton('Time Attack!', false, isPremium: true),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildModeButton('Limited', false, isPremium: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Difficulty',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: buttonSpacing),
              child: Row(
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildDifficultyButton('Easy'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildDifficultyButton('Medium'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildDifficultyButton('Hard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            Center(
              child: SizedBox(
                width: 220,
                height: 33,
                child: ElevatedButton(
                  onPressed: () => _startGame(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.5),
                    ),
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, bool enabled, {bool isPremium = false}) {
    final isSelected = _selectedMode == mode && enabled;

    return Expanded(
      child: SizedBox(
        height: 30,
        child: ElevatedButton(
          onPressed: enabled ? () {
            setState(() {
              _selectedMode = mode;
            });
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.brown.shade400,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.brown.shade400,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            mode,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;

    return Expanded(
      child: SizedBox(
        height: 30,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedDifficulty = difficulty;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.brown.shade400,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            difficulty,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}