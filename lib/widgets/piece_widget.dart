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
  });

  Widget _buildPieceContent() {
    return SizedBox(
      width: piece.pattern[0].length * cellSize,
      height: piece.pattern.length * cellSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(piece.pattern.length, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(piece.pattern[row].length, (col) {
              final isActive = piece.pattern[row][col];
              return GestureDetector(
                onTap: isActive ? onTap : null,
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: isActive ? piece.color : Colors.transparent,
                    border: isActive ? Border.all(color: Colors.black26) : null,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (position != null) {
      return Draggable<ChockABlockPiece>(
        data: piece,
        feedback: Opacity(
          opacity: 0.5,
          child: _buildPieceContent(),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildPieceContent(),
        ),
        child: _buildPieceContent(),
      );
    }

    return _buildPieceContent();
  }
}