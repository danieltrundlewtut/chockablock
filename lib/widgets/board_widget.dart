import 'package:chockablock/widgets/piece_widget.dart';

import '../models/piece.dart';
import 'package:flutter/material.dart';
import '../models/board_position.dart';

class GameBoard extends StatefulWidget {
  final double cellSize;
  final Map<String, BoardPosition> piecePlacements;
  final List<ChockABlockPiece> pieces;
  final Function(ChockABlockPiece) onPieceRemoved;

  const GameBoard({
    super.key,
    required this.cellSize,
    required this.piecePlacements,
    required this.pieces,
    required this.onPieceRemoved,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  BoardPosition? hoverPosition;
  ChockABlockPiece? hoverPiece;
  bool isValidPlacement = false;

  BoardPosition _getBoardPosition(Offset localPosition) {
    // Snap to grid by rounding to nearest cell
    final row = (localPosition.dy / widget.cellSize).round();
    final col = (localPosition.dx / widget.cellSize).round();
    return BoardPosition(row, col);
  }

  bool _isValidPosition(BoardPosition position, ChockABlockPiece piece) {
    // Check if any part of the piece would be outside the board
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          // Check board boundaries
          if (boardRow < 0 || boardRow >= 5 || boardCol < 0 || boardCol >= 11) {
            return false;
          }

          // Check collision with other pieces
          // TODO: Implement collision detection with placed pieces
        }
      }
    }
    return true;
  }

  List<Positioned> _buildPreviewCells() {
    if (hoverPosition == null || hoverPiece == null) return [];

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

          // Show all cells of the piece, even if out of bounds (they'll be red)
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

  @override
  Widget build(BuildContext context) {
    return DragTarget<ChockABlockPiece>(
      onWillAccept: (piece) => true,
      onAccept: (piece) {
        if (hoverPosition != null && isValidPlacement) {
          // Handle piece placement
        }
      },
      onLeave: (piece) {
        setState(() {
          hoverPosition = null;
          hoverPiece = null;
          isValidPlacement = false;
        });
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
            clipBehavior: Clip.none, // Allow preview to overflow
            children: [
              // Base grid
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
              // Placed pieces
              ...widget.piecePlacements.entries.map((entry) {
                final piece = widget.pieces.firstWhere((p) => p.id == entry.key);
                final position = entry.value;
                return Positioned(
                  left: position.col * widget.cellSize,
                  top: position.row * widget.cellSize,
                  child: GestureDetector(
                    onTap: () => widget.onPieceRemoved(piece),
                    child: PieceWidget(
                      piece: piece,
                      cellSize: widget.cellSize,
                    ),
                  ),
                );
              }),
              // Preview cells
              ..._buildPreviewCells(),
            ],
          ),
        );
      },
    );
  }
}