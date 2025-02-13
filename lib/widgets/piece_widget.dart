import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceWidget extends StatelessWidget {
  final ChockABlockPiece piece;
  final double cellSize;
  final VoidCallback onTap;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: piece.pattern[0].length * cellSize,
        height: piece.pattern.length * cellSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: piece.pattern.map((row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((isActive) {
                return Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: isActive ? piece.color : Colors.transparent,
                    border: isActive ? Border.all(color: Colors.black26) : null,
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}