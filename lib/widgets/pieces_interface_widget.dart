import 'package:flutter/material.dart';
import '../models/piece.dart';
import 'piece_widget.dart';

class PiecesInterface extends StatefulWidget {
  final List<ChockABlockPiece> pieces;
  final double cellSize;
  final ChockABlockPiece? draggingPiece;
  final Function(ChockABlockPiece) onDragStarted;
  final Function(ChockABlockPiece) onDragEnded;

  const PiecesInterface({
    super.key,
    required this.pieces,
    required this.cellSize,
    required this.draggingPiece,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<PiecesInterface> createState() => _PiecesInterfaceState();
}

class _PiecesInterfaceState extends State<PiecesInterface> {
  void onPieceTapped(ChockABlockPiece piece) {
    setState(() {
      piece.rotateRight();
    });
  }

  void onPieceLongPressed(ChockABlockPiece piece) {
    setState(() {
      piece.flipPiece();
    });
  }

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
          children: widget.pieces.map((piece) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () => onPieceTapped(piece),
                onLongPress: () => onPieceLongPressed(piece),
                child: Draggable<ChockABlockPiece>(
                  data: piece,
                  feedback: Transform.translate(
                    offset: Offset(
                      -widget.cellSize * piece.pattern[0].length / 2,
                      -widget.cellSize * piece.pattern.length / 2,
                    ),
                    child: PieceWidget(
                      piece: piece,
                      position: piece.position,
                      cellSize: widget.cellSize * 2,
                      onTap: () {},
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: PieceWidget(
                      piece: piece,
                      position: null,
                      cellSize: widget.cellSize,
                      onTap: () {},
                    ),
                  ),
                  onDragStarted: () => widget.onDragStarted(piece),
                  onDragEnd: (_) => widget.onDragEnded(piece),
                  child: PieceWidget(
                    piece: piece,
                    position: null,
                    cellSize: widget.cellSize,
                    onTap: () => onPieceTapped(piece),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}