import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../enums/game_difficulty_enum.dart';

class PuzzleManager {
  // Static list for in-memory storage of puzzles during the app session
  static List<Map<String, dynamic>> savedPuzzles = [];

  // Cached puzzles from assets file
  static List<Map<String, dynamic>>? _cachedPuzzles;

  // Debug flag to print detailed information
  static bool debugMode = true;

  // Load all puzzles from the assets file
  static Future<List<Map<String, dynamic>>> loadAllPuzzles() async {
    // Return cached puzzles if available
    if (_cachedPuzzles != null) {
      return _cachedPuzzles!;
    }

    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/puzzles.json');

      if (debugMode) {
        print('Loaded puzzle JSON: ${jsonString.substring(0, min(100, jsonString.length))}...');
      }

      // Parse the JSON string
      final List<dynamic> jsonData = json.decode(jsonString);

      if (debugMode) {
        print('Parsed ${jsonData.length} puzzles from JSON');
      }

      // Convert to a List of Maps
      _cachedPuzzles = jsonData.map((puzzle) => puzzle as Map<String, dynamic>).toList();

      // Log the difficulties found
      if (debugMode) {
        final difficultiesFound = _cachedPuzzles!
            .map((p) => p['calculatedDifficulty'])
            .toSet()
            .toList();
        print('Difficulties found in puzzles: $difficultiesFound');
      }

      return _cachedPuzzles!;
    } catch (e) {
      print('Error loading puzzles: $e');
      return [];
    }
  }

  // Get a puzzle by seed value
  static Future<Map<String, dynamic>?> getPuzzleBySeed(int seed) async {
    final allPuzzles = await loadAllPuzzles();

    try {
      final matchingPuzzle = allPuzzles.firstWhere(
            (puzzle) => puzzle['seed'] == seed,
        orElse: () => throw Exception('No puzzle found with seed $seed'),
      );

      if (debugMode) {
        print('Found puzzle with seed $seed: ${matchingPuzzle['calculatedDifficulty']}');
      }

      return matchingPuzzle;
    } catch (e) {
      print('Error finding puzzle by seed: $e');
      return null;
    }
  }

  // Load puzzles by difficulty
  static Future<List<Map<String, dynamic>>> loadPuzzlesByDifficulty(String difficulty) async {
    final allPuzzles = await loadAllPuzzles();

    // Check for case-insensitive match with calculatedDifficulty
    final matchingPuzzles = allPuzzles.where((puzzle) {
      final puzzleDifficulty = puzzle['calculatedDifficulty']?.toString().toLowerCase();
      return puzzleDifficulty == difficulty.toLowerCase();
    }).toList();

    if (debugMode) {
      print('Found ${matchingPuzzles.length} puzzles with difficulty: $difficulty');
    }

    return matchingPuzzles;
  }

  // Get a random puzzle with a specific difficulty
  static Future<Map<String, dynamic>?> getRandomPuzzle({String? difficulty}) async {
    List<Map<String, dynamic>> puzzles;

    if (difficulty != null) {
      puzzles = await loadPuzzlesByDifficulty(difficulty);
    } else {
      puzzles = await loadAllPuzzles();
    }

    if (puzzles.isEmpty) {
      return null;
    }

    final random = Random();
    return puzzles[random.nextInt(puzzles.length)];
  }

  // Configure the pieces based on the puzzle data
  static void configurePiecesFromPuzzleData(
      Map<String, dynamic> puzzleData,
      List<ChockABlockPiece> pieces
      ) {
    try {
      // First reset all pieces (clear any previous state)
      for (var piece in pieces) {
        piece.resetOrientation();
        piece.position = null;
        piece.isStartingPiece = false;
      }

      // Get starting pieces from the puzzle data
      final startingPieces = puzzleData['startingPieces'] as List<dynamic>;

      if (debugMode) {
        print('Configuring ${startingPieces.length} starting pieces');
      }

      // Configure starting pieces
      for (var startingPiece in startingPieces) {
        final pieceId = startingPiece['id'];
        final row = startingPiece['row'];
        final col = startingPiece['col'];
        final rotation = startingPiece['rotation'];
        final isFlipped = startingPiece['isFlipped'];

        if (debugMode) {
          print('Setting up piece: $pieceId at $row,$col (rotation: $rotation, flipped: $isFlipped)');
        }

        // Find the piece in the list
        final piece = pieces.firstWhere((p) => p.id == pieceId,
            orElse: () => throw Exception('Piece $pieceId not found'));

        // Configure the piece
        piece.isStartingPiece = true;
        piece.resetOrientation(); // First reset to original state

        // Apply flip if needed
        if (isFlipped == true) {
          piece.flipPiece();
        }

        // Apply rotations
        for (int i = 0; i < (rotation ?? 0); i++) {
          piece.rotateRight();
        }

        // Set position last (after orientation is set)
        piece.position = BoardPosition(row, col);
      }
    } catch (e) {
      print('Error configuring pieces: $e');
      throw Exception('Failed to configure pieces: $e');
    }
  }

  // Calculate difficulty based on time and moves
  static String calculateDifficulty(int timeMs, int moves) {
    // Convert time to seconds for easier reading
    final timeSeconds = timeMs / 1000;

    // Base scoring - higher score means more difficult
    double difficultyScore = 0;

    // Time-based scoring (weight: 60%)
    // Medium puzzle example: ~357 seconds (6 minutes)
    if (timeSeconds < 180) { // Under 3 minutes
      difficultyScore += 0;
    } else if (timeSeconds < 420) { // 3-7 minutes
      difficultyScore += 1.5;
    } else { // Over 7 minutes
      difficultyScore += 3;
    }

    // Moves-based scoring (weight: 40%)
    // Medium puzzle example: ~129 moves
    if (moves < 70) {
      difficultyScore += 0;
    } else if (moves < 160) {
      difficultyScore += 1;
    } else {
      difficultyScore += 2;
    }

    // Classification based on overall score
    // Maximum possible score: 3 + 2 = 5
    if (difficultyScore < 1.5) {
      return "Easy";
    } else if (difficultyScore < 3.0) {
      return "Medium";
    } else {
      return "Hard";
    }
  }

  // Create puzzle data in the specified format
  static Map<String, dynamic> createPuzzleData({
    required int seed,
    required List<ChockABlockPiece> startingPieces,
    required List<ChockABlockPiece> placedPieces,
    required int filledCells,
    required int timeMs,
    required int moves,
  }) {
    // Create placements map
    final Map<String, dynamic> placements = {};

    // Get non-starting pieces in placement order
    int orderIndex = 0;
    for (var piece in placedPieces) {
      if (!piece.isStartingPiece && piece.position != null) {
        placements[piece.id] = {
          'row': piece.position!.row,
          'col': piece.position!.col,
          'rotation': piece.rotationCount,
          'isFlipped': piece.isFlipped,
          'orderIndex': orderIndex++,
        };
      }
    }

    // Calculate difficulty based on time and moves
    final calculatedDifficulty = calculateDifficulty(timeMs, moves);

    // Create and return the data in the exact format specified
    return {
      'seed': seed,
      'startingPieces': startingPieces.map((piece) => {
        'id': piece.id,
        'row': piece.position!.row,
        'col': piece.position!.col,
        'rotation': piece.rotationCount,
        'isFlipped': piece.isFlipped,
      }).toList(),
      'placements': placements,
      'filledCells': filledCells,
      'time': timeMs,
      'moves': moves,
      'calculatedDifficulty': calculatedDifficulty,
    };
  }

  // Save puzzle data to memory and copy to clipboard
  static void savePuzzleData(
      BuildContext context,
      Map<String, dynamic> puzzleData
      ) {
    try {
      // Add to our in-memory list
      savedPuzzles.add(puzzleData);

      if (debugMode) {
        print('Puzzle data saved to memory. Total puzzles: ${savedPuzzles.length}');
      }

      // Automatically copy the current puzzle data to clipboard
      Clipboard.setData(ClipboardData(
          text: const JsonEncoder.withIndent('  ').convert(puzzleData)
      ));

      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puzzle data copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Show dialog with the data
      _showSavedPuzzleDialog(context, puzzleData);
    } catch (e) {
      print('Error saving puzzle data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving puzzle data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog with saved puzzle data
  static void _showSavedPuzzleDialog(
      BuildContext context,
      Map<String, dynamic> puzzleData
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Puzzle Data Saved'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✓ Saved to memory'),
                const Text('✓ Copied to clipboard'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Solved in: ${(puzzleData['time'] / 1000).toStringAsFixed(1)}s'),
                    const SizedBox(width: 15),
                    Text('Moves: ${puzzleData['moves']}'),
                  ],
                ),
                Row(
                  children: [
                    const Text('Difficulty: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      puzzleData['calculatedDifficulty'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(puzzleData['calculatedDifficulty'] ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Seed: ${puzzleData['seed']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(const JsonEncoder.withIndent('  ').convert(puzzleData)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(savedPuzzles)
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All puzzles copied to clipboard')),
                );
              },
              child: const Text('Copy All Puzzles'),
            ),
            TextButton(
              onPressed: () {
                showAllPuzzlesDialog(context);
              },
              child: const Text('View All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog with all saved puzzles
  static void showAllPuzzlesDialog(BuildContext context) {
    // Close current dialog if open
    if (ModalRoute.of(context)?.isCurrent == false) {
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Saved Puzzles'),
          content: SizedBox(
            width: double.maxFinite,
            child: savedPuzzles.isEmpty
                ? const Text('No puzzles saved yet')
                : ListView.builder(
              itemCount: savedPuzzles.length,
              itemBuilder: (context, index) {
                final puzzle = savedPuzzles[savedPuzzles.length - 1 - index];
                final difficulty = puzzle['calculatedDifficulty'] ?? 'Unknown';
                final timeSeconds = ((puzzle['time'] ?? 0) / 1000).toStringAsFixed(1);
                final moves = puzzle['moves'] ?? 0;
                final seed = puzzle['seed'] ?? 0;

                return ListTile(
                  title: Text('$difficulty puzzle (Seed: $seed)'),
                  subtitle: Text('Time: ${timeSeconds}s | Moves: $moves'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showPuzzleDetailsDialog(context, puzzle);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(savedPuzzles)
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All puzzles copied to clipboard')),
                );
              },
              child: const Text('Copy All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog with puzzle details
  static void showPuzzleDetailsDialog(BuildContext context, Map<String, dynamic> puzzle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              '${puzzle['calculatedDifficulty'] ?? 'Unknown'} Puzzle (Seed: ${puzzle['seed']})'
          ),
          content: SingleChildScrollView(
            child: Text(const JsonEncoder.withIndent('  ').convert(puzzle)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(puzzle)
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Puzzle data copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Get the difficulty enum from a string
  static GameDifficulty difficultyFromString(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return GameDifficulty.easy;
      case 'hard':
        return GameDifficulty.hard;
      case 'medium':
      default:
        return GameDifficulty.medium;
    }
  }

  // Helper method to get color based on difficulty
  static Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}