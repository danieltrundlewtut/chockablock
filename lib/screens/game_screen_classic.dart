import 'package:chockablock/models/piece.dart';
import 'package:chockablock/widgets/piece_widget.dart';
import 'package:chockablock/widgets/pieces_interface_widget.dart';
import 'package:flutter/material.dart';
import '../models/board_position.dart';
import '../widgets/board_widget.dart';
import '../data/piece_data.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<ChockABlockPiece> availablePieces = [];
  List<PieceWidget> placedPieces = [];
  ChockABlockPiece? draggingPiece;
  late double boardWidth;
  late double cellSize;

  @override
  void initState() {
    super.initState();
    availablePieces = PieceData.getAllPieces();
    // Remove MediaQuery calculations from initState
  }

  // Add this method to calculate sizes after layout
  void _updateSizes() {
    boardWidth = ((MediaQuery.of(context).size.width) * 0.6);
    cellSize = boardWidth / 11;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate sizes here instead of initState
    _updateSizes();
  }

  bool isValidPlacement(BoardPosition position, ChockABlockPiece piece) {
    // TODO: Implement actual validation logic
    return true;
  }

  void onPiecePlaced(ChockABlockPiece piece, int row, int col) {
    BoardPosition position = BoardPosition(row, col);
    if (isValidPlacement(position, piece)) {
      setState(() {
        piece.position = position;

        final pieceWidget = PieceWidget(
          key: ValueKey(piece.id),
          piece: piece,
          cellSize: cellSize,
          position: position,
          onTap: () => onPieceRemoved(piece),
        );

        if (!placedPieces.any((p) => p.piece.id == piece.id)) {
          availablePieces.removeWhere((p) => p.id == piece.id);
          placedPieces.add(pieceWidget);
        } else {
          final index = placedPieces.indexWhere((p) => p.piece.id == piece.id);
          if (index != -1) {
            placedPieces[index] = pieceWidget;
          }
        }

        draggingPiece = null;
      });
    }
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    setState(() {
      placedPieces.removeWhere((widget) => widget.piece.id == piece.id);
      if (!availablePieces.any((p) => p.id == piece.id)) {
        availablePieces.add(piece);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recalculate sizes on build to handle orientation changes
    _updateSizes();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 15),
                  Center(
                    child: GameBoard(
                      cellSize: cellSize,
                      placedPieces: placedPieces,
                      onDragUpdate: (position) {},
                      onPiecePlaced: onPiecePlaced,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: PiecesInterface(
                        pieces: availablePieces,
                        cellSize: cellSize * 0.4,
                        draggingPiece: draggingPiece,
                        onDragStarted: (piece) {
                          setState(() {
                            draggingPiece = piece;
                          });
                        },
                        onDragEnded: (piece) {
                          if (draggingPiece != null) {
                            setState(() {
                              draggingPiece = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}