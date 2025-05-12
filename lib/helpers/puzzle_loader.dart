import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/piece.dart';
import '../models/board_position.dart';
import '../enums/game_difficulty_enum.dart';

class PuzzleLoader {
  // Cached puzzles to avoid loading from disk multiple times
  static List<Map<String, dynamic>>? _cachedPuzzles;

  // Load all puzzles from the assets file
  static Future<List<Map<String, dynamic>>> loadAllPuzzles() async {
    // Return cached puzzles if available
    if (_cachedPuzzles != null) {
      return _cachedPuzzles!;
    }

    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/puzzles.json');

      // Parse the JSON string
      final List<dynamic> jsonData = json.decode(jsonString);

      // Convert to a List of Maps
      _cachedPuzzles = jsonData.map((puzzle) => puzzle as Map<String, dynamic>).toList();
      return _cachedPuzzles!;
    } catch (e) {
      print('Error loading puzzles: $e');
      return [];
    }
  }

  // Load puzzles by difficulty
  static Future<List<Map<String, dynamic>>> loadPuzzlesByDifficulty(String difficulty) async {
    final allPuzzles = await loadAllPuzzles();
    return allPuzzles.where((puzzle) =>
    puzzle['calculatedDifficulty'] == difficulty ||
        puzzle['difficulty'] == difficulty
    ).toList();
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

  static void configurePiecesFromPuzzleData(
      Map<String, dynamic> puzzleData,
      List<ChockABlockPiece> pieces
      ) {
    final startingPieces = puzzleData['startingPieces'] as List<dynamic>;

    for (var startingPiece in startingPieces) {
      final pieceId = startingPiece['id'];
      final row = startingPiece['row'];
      final col = startingPiece['col'];
      final rotation = startingPiece['rotation'];
      final isFlipped = startingPiece['isFlipped'];

      final piece = pieces.firstWhere((p) => p.id == pieceId);

      piece.position = BoardPosition(row, col);
      piece.isStartingPiece = true;

      piece.resetOrientation();

      if (isFlipped) {
        piece.flipPiece();
      }

      for (int i = 0; i < rotation; i++) {
        piece.rotateRight();
      }
    }
  }

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
}