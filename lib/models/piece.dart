import 'package:flutter/material.dart';

class ChockABlockPiece {
  final String id;
  final List<List<bool>> pattern;
  final Color color;
  int rotationDegrees = 0;
  bool isFlippedHorizontally = false;
  bool isFlippedVertically = false;

  ChockABlockPiece({
    required this.id,
    required this.pattern,
    required this.color,
  });

  // Will be implemented later for piece manipulation
  void rotateRight() {
    rotationDegrees = (rotationDegrees + 90) % 360;
  }

  void rotateLeft() {
    rotationDegrees = (rotationDegrees - 90) % 360;
  }

  void flipHorizontally() {
    isFlippedHorizontally = !isFlippedHorizontally;
  }

  void flipVertically() {
    isFlippedVertically = !isFlippedVertically;
  }
}
