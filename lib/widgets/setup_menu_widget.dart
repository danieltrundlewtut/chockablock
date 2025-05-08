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
  bool _chooseStartingPieces = false;

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
            customPieces: _chooseStartingPieces,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // More comfortable sizes
    const double buttonHeight = 32.0;
    const double fontSize = 14.0;
    const double headerFontSize = 18.0;
    const double spacing = 12.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit the height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fixed header that doesn't scroll
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Setup Game',
                    style: TextStyle(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.onBack(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: Scrollbar(
                thickness: 10.0, // Make the scrollbar visible
                radius: const Radius.circular(8.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game Mode
                      const Text(
                        'Game mode',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildModeButton('Classic', true),
                          const SizedBox(width: 10),
                          _buildModeButton('Time Attack', false, isPremium: true),
                          const SizedBox(width: 10),
                          _buildModeButton('Move Limit', false, isPremium: true),
                        ],
                      ),
                      const SizedBox(height: spacing),

                      // Difficulty
                      const Text(
                        'Difficulty',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDifficultyButton('Easy'),
                          const SizedBox(width: 10),
                          _buildDifficultyButton('Medium'),
                          const SizedBox(width: 10),
                          _buildDifficultyButton('Hard'),
                        ],
                      ),
                      const SizedBox(height: spacing),

                      // Choose starting pieces
                      const Text(
                        'Choose starting piece(s)?',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildChoiceButton('No', !_chooseStartingPieces),
                          const SizedBox(width: 10),
                          _buildChoiceButton('Yes', _chooseStartingPieces),
                        ],
                      ),

                      if (_chooseStartingPieces) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              // To be implemented later
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Choose piece(s)', style: TextStyle(fontSize: fontSize)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Play button
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: buttonHeight + 4,
                          child: ElevatedButton(
                            onPressed: () => _startGame(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              'Play',
                              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        height: 40, // Increased button height
        child: ElevatedButton(
          onPressed: enabled ? () {
            setState(() {
              _selectedMode = mode;
            });
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  mode,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 14)
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty) {
    final isSelected = _selectedDifficulty == difficulty;

    return Expanded(
      child: SizedBox(
        height: 40, // Increased button height
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedDifficulty = difficulty;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          child: Text(
            difficulty,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String choice, bool isSelected) {
    return Expanded(
      child: SizedBox(
        height: 40, // Increased button height
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _chooseStartingPieces = choice == 'Yes';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          child: Text(
            choice,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}