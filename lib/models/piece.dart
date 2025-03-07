import 'package:chockablock/models/board_position.dart';
import 'package:flutter/material.dart';

class ChockABlockPiece {
  final String id;
  List<List<bool>> pattern;
  final Color color;
  BoardPosition? position;
  bool isStartingPiece = false;

  ChockABlockPiece({
    required this.id,
    required this.pattern,
    required this.color,
  });

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
  }

  void flipPiece() {
    pattern = pattern.map((row) => row.reversed.toList()).toList();
  }
}
