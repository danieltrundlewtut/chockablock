import 'package:flutter/material.dart';
import '../widgets/piece_widget.dart';
import '../models/piece.dart';
import '../models/board_position.dart';

class GameBoard extends StatefulWidget {
  final double cellSize;
  final List<PieceWidget> placedPieces;
  final Function(Offset position) onDragUpdate;
  final Function(ChockABlockPiece piece, int row, int col) onPiecePlaced;

  const GameBoard({
    super.key,
    required this.cellSize,
    required this.placedPieces,
    required this.onDragUpdate,
    required this.onPiecePlaced,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  BoardPosition? hoverPosition;
  ChockABlockPiece? hoverPiece;
  bool isValidPlacement = false;
  bool isDragging = false;

  BoardPosition _getBoardPosition(Offset localPosition) {
    final row = (localPosition.dy / widget.cellSize).round();
    final col = (localPosition.dx / widget.cellSize).round();
    return BoardPosition(row, col);
  }

  bool _doPiecesCollide(ChockABlockPiece piece, BoardPosition position, ChockABlockPiece placedPiece) {
    if (placedPiece.position == null) return false;

    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          int newRow = position.row + row;
          int newCol = position.col + col;

          for (int pieceX = 0; pieceX < placedPiece.pattern.length; pieceX++) {
            for (int pieceY = 0; pieceY < placedPiece.pattern[pieceX].length; pieceY++) {
              if (placedPiece.pattern[pieceX][pieceY]) {
                int placedRow = placedPiece.position!.row + pieceX;
                int placedCol = placedPiece.position!.col + pieceY;

                if (newRow == placedRow && newCol == placedCol) {
                  return true;
                }
              }
            }
          }
        }
      }
    }
    return false;
  }

  bool _isValidPosition(BoardPosition position, ChockABlockPiece piece) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          if (boardRow < 0 || boardRow >= 5 ||
              boardCol < 0 || boardCol >= 11) {
            return false;
          }

          for (var placedPiece in widget.placedPieces) {
            if (_doPiecesCollide(piece, position, placedPiece.piece)) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  List<Positioned> _buildPreviewCells() {
    // Only show preview cells if actively dragging
    if (!isDragging || hoverPosition == null || hoverPiece == null) return [];

    final Color previewColor = isValidPlacement
        ? Colors.yellow
        : Colors.red;

    List<Positioned> previewCells = [];
    final pattern = hoverPiece!.pattern;

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col]) {
          final boardRow = hoverPosition!.row + row;
          final boardCol = hoverPosition!.col + col;

          previewCells.add(
            Positioned(
              left: boardCol * widget.cellSize,
              top: boardRow * widget.cellSize,
              child: Container(
                width: widget.cellSize,
                height: widget.cellSize,
                decoration: BoxDecoration(
                  color: previewColor.withOpacity(0.3),
                  border: Border.all(
                    color: previewColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    return previewCells;
  }

  void _clearPreview() {
    setState(() {
      hoverPosition = null;
      hoverPiece = null;
      isValidPlacement = false;
      isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<ChockABlockPiece>(
      onWillAccept: (piece) {
        setState(() {
          isDragging = true;
        });
        return true;
      },
      onAccept: (piece) {
        if (hoverPosition != null && isValidPlacement) {
          widget.onPiecePlaced(piece, hoverPosition!.row, hoverPosition!.col);
        }
        _clearPreview();
      },
      onLeave: (piece) {
        _clearPreview();
      },
      onMove: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        final newPosition = _getBoardPosition(localPosition);

        setState(() {
          hoverPosition = newPosition;
          hoverPiece = details.data;
          isValidPlacement = _isValidPosition(newPosition, details.data);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black38),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(11, (col) {
                      return Container(
                        width: widget.cellSize,
                        height: widget.cellSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                      );
                    }),
                  );
                }),
              ),
              ...widget.placedPieces.map((piece) {
                if (piece.position == null) return const SizedBox.shrink();
                return Positioned(
                  left: piece.position!.col * widget.cellSize,
                  top: piece.position!.row * widget.cellSize,
                  child: piece,
                );
              }),
              ..._buildPreviewCells(),
            ],
          ),
        );
      },
    );
  }
}