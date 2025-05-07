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
  BoardPosition? newPosition;
  ChockABlockPiece? hoverPiece;
  bool isValidPlacement = false;
  bool isDragging = false;
  bool isFromInterface = false;

  BoardPosition _getBoardPosition(Offset localPosition, ChockABlockPiece piece) {
    final pieceHeight = piece.pattern.length;
    final pieceWidth = piece.pattern[0].length;

    final adjustedX = isFromInterface
        ? localPosition.dx - (pieceWidth * widget.cellSize / 4)
        : localPosition.dx;
    final adjustedY = isFromInterface
        ? localPosition.dy - (pieceHeight * widget.cellSize / 4)
        : localPosition.dy;

    final col = (adjustedX / widget.cellSize).round();
    final row = (adjustedY / widget.cellSize).round();

    return BoardPosition(row, col);
  }

  // Modified collision detection function that only considers active cells
  bool _doPiecesCollide(ChockABlockPiece piece, BoardPosition position, ChockABlockPiece placedPiece) {
    if (placedPiece.position == null) return false;
    if (placedPiece == piece) return false;

    // Get active cells for both pieces
    List<List<int>> activeCells = piece.getActiveCells();
    List<List<int>> placedActiveCells = placedPiece.getActiveCells();

    // Check collisions only for active cells
    for (final activeCell in activeCells) {
      int newRow = position.row + activeCell[0];
      int newCol = position.col + activeCell[1];

      for (final placedCell in placedActiveCells) {
        int placedRow = placedPiece.position!.row + placedCell[0];
        int placedCol = placedPiece.position!.col + placedCell[1];

        if (newRow == placedRow && newCol == placedCol) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isValidPosition(BoardPosition position, ChockABlockPiece piece) {
    // Get only active cells
    List<List<int>> activeCells = piece.getActiveCells();

    for (final cell in activeCells) {
      final boardRow = position.row + cell[0];
      final boardCol = position.col + cell[1];

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
    return true;
  }

  List<Positioned> _buildPreviewCells() {
    // Only show preview cells if actively dragging
    if (!isDragging || hoverPosition == null || hoverPiece == null) return [];

    final Color previewColor = isValidPlacement
        ? Colors.yellow
        : Colors.red;

    List<Positioned> previewCells = [];

    // Only show preview for active cells
    List<List<int>> activeCells = hoverPiece!.getActiveCells();

    for (final cell in activeCells) {
      final boardRow = hoverPosition!.row + cell[0];
      final boardCol = hoverPosition!.col + cell[1];

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

  // Helper to find the piece at a specific board position
  ChockABlockPiece? _findPieceAtPosition(int boardRow, int boardCol) {
    for (var placedPieceWidget in widget.placedPieces) {
      final piece = placedPieceWidget.piece;
      if (piece.position == null) continue;

      // Check if any active cell in this piece is at the specified board position
      for (int row = 0; row < piece.pattern.length; row++) {
        for (int col = 0; col < piece.pattern[row].length; col++) {
          if (piece.pattern[row][col]) {
            final pieceRow = piece.position!.row + row;
            final pieceCol = piece.position!.col + col;

            if (pieceRow == boardRow && pieceCol == boardCol) {
              return piece;
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<ChockABlockPiece>(
      onWillAccept: (piece) {
        setState(() {
          isDragging = true;
          isFromInterface = !widget.placedPieces.any((p) => p.piece.id == piece?.id);
        });
        return true;
      },
      onAccept: (piece) {
        if (hoverPosition != null && isValidPlacement) {
          widget.onPiecePlaced(piece, hoverPosition!.row, hoverPosition!.col);
        }
        _clearPreview();
        isFromInterface = false;
      },
      onLeave: (piece) {
        _clearPreview();
        isFromInterface = false;
      },
      onMove: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        newPosition = _getBoardPosition(localPosition, details.data);

        setState(() {
          hoverPosition = newPosition;
          hoverPiece = details.data;
          isValidPlacement = _isValidPosition(newPosition!, details.data);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
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