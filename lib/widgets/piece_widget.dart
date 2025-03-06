import 'package:chockablock/models/board_position.dart';
import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceWidget extends StatelessWidget {
  final ChockABlockPiece piece;
  final double cellSize;
  final VoidCallback onTap;
  final BoardPosition? position;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onTap,
    required this.position,
    required Null Function(dynamic touchPosition, dynamic draggedPiece) onDragStart,
  });

  @override
  Widget build(BuildContext context) {
    // Create a gesture detector that detects drag initiation
    Widget pieceContent = SizedBox(
      width: piece.pattern[0].length * cellSize,
      height: piece.pattern.length * cellSize,
      child: Stack(
        children: [
          // First, create the visual representation without any interactivity
          Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(piece.pattern.length, (row) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(piece.pattern[row].length, (col) {
                  final isActive = piece.pattern[row][col];
                  return Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: isActive ? piece.color : Colors.transparent,
                      border: isActive ? Border.all(color: Colors.black26) : null,
                    ),
                  );
                }),
              );
            }),
          ),

          // Then overlay invisible gesture detectors only on the active cells
          ...List.generate(piece.pattern.length, (row) {
            return List.generate(piece.pattern[row].length, (col) {
              final isActive = piece.pattern[row][col];
              if (!isActive) return const SizedBox.shrink(); // No gesture detector for inactive cells

              return Positioned(
                top: row * cellSize,
                left: col * cellSize,
                child: GestureDetector(
                  onTap: isActive ? onTap : null,
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    color: Colors.transparent, // Invisible but detects gestures
                  ),
                ),
              );
            });
          }).expand((widgets) => widgets),
        ],
      ),
    );

    // If this piece is on the board, make the active cells draggable
    if (position != null) {
      return Stack(
        children: [
          pieceContent, // Visual representation

          // Overlay draggable widgets only on active cells
          ...List.generate(piece.pattern.length, (row) {
            return List.generate(piece.pattern[row].length, (col) {
              final isActive = piece.pattern[row][col];
              if (!isActive) return const SizedBox.shrink();

              return Positioned(
                top: row * cellSize,
                left: col * cellSize,
                child: Draggable<ChockABlockPiece>(
                  data: piece,
                  feedback: Opacity(
                    opacity: 0.5,
                    child: pieceContent,
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: pieceContent,
                  ),
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    color: Colors.transparent, // Invisible but enables dragging
                  ),
                ),
              );
            });
          }).expand((widgets) => widgets),
        ],
      );
    }

    return pieceContent;
  }
}