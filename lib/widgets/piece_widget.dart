import 'package:chockablock/models/board_position.dart';
import 'package:flutter/material.dart';
import '../helpers/tap_detection.dart';
import '../models/piece.dart';

class PieceWidget extends StatelessWidget {
  final ChockABlockPiece piece;
  final double cellSize;
  final VoidCallback onTap;
  final BoardPosition? position;
  final Function(Offset, ChockABlockPiece)? onDragStart;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onTap,
    required this.position,
    this.onDragStart,
  });

  @override
  Widget build(BuildContext context) {
    // Instead of using a simple SizedBox, we'll create a Stack with individually positioned active cells
    // This ensures only active cells respond to taps
    Widget pieceContent = SizedBox(
      width: piece.pattern[0].length * cellSize,
      height: piece.pattern.length * cellSize,
      child: Stack(
        children: [
          // First, we'll create the visual representation of all cells
          for (int row = 0; row < piece.pattern.length; row++)
            for (int col = 0; col < piece.pattern[row].length; col++)
              if (piece.pattern[row][col]) // Only render active cells
                Positioned(
                  top: row * cellSize,
                  left: col * cellSize,
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: piece.color,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                ),

          // Then we overlay tap detectors ONLY on active cells
          for (int row = 0; row < piece.pattern.length; row++)
            for (int col = 0; col < piece.pattern[row].length; col++)
              if (piece.pattern[row][col] && !piece.isStartingPiece) // Only add gesture detectors to active cells
                Positioned(
                  top: row * cellSize,
                  left: col * cellSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque, // Important for proper hit testing
                    onTap: onTap,
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      color: Colors.transparent, // Invisible but captures gestures
                    ),
                  ),
                ),
        ],
      ),
    );

    // If this piece is on the board and not a starting piece, make it draggable
    if (position != null && !piece.isStartingPiece) {
      return CustomDraggableWidget(
        piece: piece,
        cellSize: cellSize,
        pieceContent: pieceContent,
        onDragStart: onDragStart,
      );
    }

    return pieceContent;
  }
}