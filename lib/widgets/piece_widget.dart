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
    // Calculate the total width and height of the piece
    final int totalWidth = piece.pattern[0].length;
    final int totalHeight = piece.pattern.length;

    Widget pieceContent = SizedBox(
      width: totalWidth * cellSize,
      height: totalHeight * cellSize,
      child: Stack(
        children: [
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

          if (position == null && !piece.isStartingPiece)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  color: Colors.transparent, // Invisible
                ),
              ),
            ),

          if (position != null && !piece.isStartingPiece)
            for (int row = 0; row < piece.pattern.length; row++)
              for (int col = 0; col < piece.pattern[row].length; col++)
                if (piece.pattern[row][col]) // Only add gesture detectors to active cells
                  Positioned(
                    top: row * cellSize,
                    left: col * cellSize,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
        ],
      ),
    );

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