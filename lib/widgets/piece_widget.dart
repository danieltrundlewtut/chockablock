import 'package:chockablock/models/board_position.dart';
import 'package:flutter/gestures.dart';
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
                onTap: isActive && !piece.isStartingPiece ? onTap : null,
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
    if (position != null && !piece.isStartingPiece) {
      return CustomDraggableWidget(
        piece: piece,
        cellSize: cellSize,
        pieceContent: _buildPieceContent(),
      );
    }

    return _buildPieceContent();
  }
}

class CustomDraggableWidget extends StatefulWidget {
  final ChockABlockPiece piece;
  final double cellSize;
  final Widget pieceContent;

  const CustomDraggableWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.pieceContent,
  });

  @override
  State<CustomDraggableWidget> createState() => _CustomDraggableWidgetState();
}

class _CustomDraggableWidgetState extends State<CustomDraggableWidget> {
  bool canDrag = false;
  Offset? dragStartPosition;

  @override
  Widget build(BuildContext context) {
    return Draggable<ChockABlockPiece>(
      data: widget.piece,
      feedback: Opacity(
        opacity: 0.5,
        child: widget.pieceContent,
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.pieceContent,
      ),
      onDragStarted: () {
        if (!canDrag) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero);
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(
            position: position,
          ));
        }
      },
      child: GestureDetector(
        onPanDown: (details) {
          final localPosition = details.localPosition;
          final row = (localPosition.dy / widget.cellSize).floor();
          final col = (localPosition.dx / widget.cellSize).floor();

          canDrag = false;
          if (row >= 0 && row < widget.piece.pattern.length &&
              col >= 0 && col < widget.piece.pattern[0].length) {
            canDrag = widget.piece.pattern[row][col];
          }

          dragStartPosition = details.globalPosition;
        },
        onPanUpdate: (details) {
          if (!canDrag && dragStartPosition != null) {
            if ((details.globalPosition - dragStartPosition!).distance > 10) {
              // Reset for safety
              dragStartPosition = null;
            }
          }
        },
        onPanEnd: (_) {
          canDrag = false;
          dragStartPosition = null;
        },
        child: widget.pieceContent,
      ),
    );
  }
}