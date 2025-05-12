import 'package:chockablock/models/board_position.dart';
import 'package:flutter/material.dart';

class ChockABlockPiece {
  final String id;
  List<List<bool>> pattern;
  late final List<List<bool>> ogPattern;
  final Color color;
  BoardPosition? position;
  bool isStartingPiece = false;

  int rotationCount = 0;
  bool isFlipped = false;

  ChockABlockPiece({
    required this.id,
    required this.pattern,
    required this.color,
  }) {
    ogPattern = List.generate(
      pattern.length,
          (row) => List.generate(
        pattern[row].length,
            (col) => pattern[row][col],
      ),
    );
  }

  List<List<int>> getActiveCells() {
    List<List<int>> activeCells = [];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col]) {
          activeCells.add([row, col]);
        }
      }
    }

    return activeCells;
  }

  void rotateRight() {
    final rows = pattern.length;
    final cols = pattern[0].length;
    List<List<bool>> rotated = List.generate(
        cols,
            (i) => List.generate(rows, (j) => false)
    );

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        rotated[j][rows - 1 - i] = pattern[i][j];
      }
    }
    pattern = rotated;

    rotationCount = (rotationCount + 1) % 4;
  }

  void flipPiece() {
    pattern = pattern.map((row) => row.reversed.toList()).toList();

    isFlipped = !isFlipped;
  }

  void resetOrientation() {
    pattern = List.generate(
      ogPattern.length,
          (row) => List.generate(
        ogPattern[row].length,
            (col) => ogPattern[row][col],
      ),
    );

    // Reset rotation and flip state
    rotationCount = 0;
    isFlipped = false;
  }

  // Utility method to set orientation to a specific state
  void setOrientation({required int rotations, required bool flipped}) {
    // First reset to original orientation
    resetOrientation();

    // Apply flipping if needed
    if (flipped) {
      flipPiece();
    }

    // Apply rotations
    for (int i = 0; i < rotations; i++) {
      rotateRight();
    }
  }
}