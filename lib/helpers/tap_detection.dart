import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/piece.dart';

class CustomDraggableWidget extends StatefulWidget {
  final ChockABlockPiece piece;
  final double cellSize;
  final Widget pieceContent;
  final Function(Offset, ChockABlockPiece)? onDragStart;

  const CustomDraggableWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.pieceContent,
    this.onDragStart,
  });

  @override
  State<CustomDraggableWidget> createState() => _CustomDraggableWidgetState();
}

class _CustomDraggableWidgetState extends State<CustomDraggableWidget> {
  bool canDrag = false;
  Offset? dragStartPosition;

  // Helper method to check if a local position is on an active cell
  bool isPositionOnActiveCell(Offset localPosition) {
    final row = (localPosition.dy / widget.cellSize).floor();
    final col = (localPosition.dx / widget.cellSize).floor();

    // Check if the coordinates are within the pattern bounds
    if (row >= 0 && row < widget.piece.pattern.length &&
        col >= 0 && col < widget.piece.pattern[0].length) {
      // Only return true if the cell at this position is active
      return widget.piece.pattern[row][col];
    }
    return false;
  }

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
        // Call onDragStart callback if provided
        if (widget.onDragStart != null && dragStartPosition != null) {
          widget.onDragStart!(dragStartPosition!, widget.piece);
        }

        if (!canDrag) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero);
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(
            position: position,
          ));
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // Ensure hit testing is done properly
        onPanDown: (details) {
          final localPosition = details.localPosition;
          // Only set canDrag to true if the tap is on an active cell
          canDrag = isPositionOnActiveCell(localPosition);
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