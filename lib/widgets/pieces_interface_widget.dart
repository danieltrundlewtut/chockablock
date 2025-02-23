import 'package:flutter/material.dart';
import '../models/piece.dart';
import 'piece_widget.dart';

class PiecesInterface extends StatefulWidget {
  final List<ChockABlockPiece> pieces;
  final List<PieceWidget> placedPieces;
  final double cellSize;
  final ChockABlockPiece? draggingPiece;
  final Function(ChockABlockPiece) onDragStarted;
  final Function(ChockABlockPiece) onDragEnded;

  const PiecesInterface({
    super.key,
    required this.pieces,
    required this.placedPieces,
    required this.cellSize,
    required this.draggingPiece,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  State<PiecesInterface> createState() => _PiecesInterfaceState();
}

class _PiecesInterfaceState extends State<PiecesInterface> {
  // Store initial pieces to maintain consistent container size
  late final List<ChockABlockPiece> allPieces;

  @override
  void initState() {
    super.initState();
    allPieces = List.from(widget.pieces);
  }

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

  int _pieceWidthDefiner(ChockABlockPiece piece) {
    if (piece.id == "clifford" ||
        piece.id == "betty" ||
        piece.id == "ray") {
      return 4;
    }
    else if (piece.id == "billie") {
      return 2;
    }
    else {
      return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: allPieces.map((piece) {
          final isAvailable = widget.pieces.any((p) => p.id == piece.id);
          final isPlaced = widget.placedPieces.any((p) => p.piece.id == piece.id);

          return Container(
            width: _pieceWidthDefiner(piece) * widget.cellSize,
            height: 4 * widget.cellSize * 1.25,
            alignment: Alignment.center,
            child: !isAvailable || isPlaced
                ? Opacity(
                opacity: 0.35,
                child: PieceWidget(
                piece: piece,
                position: null,
                cellSize: widget.cellSize,
                onTap: () => {},
              ),
            )
            : GestureDetector(
              onTap: () => onPieceTapped(piece),
              onLongPress: () => onPieceLongPressed(piece),
              child: Draggable<ChockABlockPiece>(
                data: piece,
                feedback: Opacity(
                  opacity: 0.5,
                  child: Transform.translate(
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
    );
  }
}