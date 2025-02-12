import 'package:flutter/material.dart';
import '../models/piece.dart';
import 'piece_widget.dart';

class PiecesInterface extends StatelessWidget {
  final List<ChockABlockPiece> pieces;
  final double cellSize;

  final ChockABlockPiece? draggingPiece;
  final Function(ChockABlockPiece) onDragStarted;
  final VoidCallback onDragEnded;

  const PiecesInterface({
    super.key,
    required this.pieces,
    required this.cellSize,
    required this.draggingPiece,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: pieces.map((piece) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Draggable<ChockABlockPiece>(
                data: piece,
                feedback: PieceWidget(
                  piece: piece,
                  cellSize: cellSize * 2,
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: PieceWidget(
                    piece: piece,
                    cellSize: cellSize,
                  ),
                ),
                onDragStarted: () => onDragStarted(piece),
                onDragEnd: (_) => onDragEnded(),
                child: PieceWidget(
                  piece: piece,
                  cellSize: cellSize,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}