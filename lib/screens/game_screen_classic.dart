import 'package:chockablock/models/piece.dart';
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
  List<ChockABlockPiece> placedPieces = [];
  ChockABlockPiece? draggingPiece;
  Map<String, BoardPosition> piecePlacements = {};

  @override
  void initState() {
    super.initState();
    availablePieces = PieceData.getAllPieces();
  }

  bool isValidPlacement(BoardPosition position, ChockABlockPiece piece) {
    // TODO: Implement actual validation logic
    return true;
  }

  void onPiecePlaced(ChockABlockPiece piece, BoardPosition position) {
    if (isValidPlacement(position, piece)) {
      setState(() {
        if (draggingPiece != null) {
          // If the piece was already placed somewhere, remove old placement
          piecePlacements.remove(piece.id);

          // Add new placement
          piecePlacements[piece.id] = position;

          // If piece wasn't previously placed, move it from available to placed
          if (!placedPieces.contains(piece)) {
            availablePieces.remove(piece);
            placedPieces.add(piece);
          }
        }
      });
    }
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    setState(() {
      placedPieces.remove(piece);
      availablePieces.add(piece);
      piecePlacements.remove(piece.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardWidth = (screenWidth * 0.6);
    final cellSize = boardWidth / 11;

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
                  const SizedBox(height: 16),
                  Center(
                    child: GameBoard(
                      cellSize: cellSize,
                      piecePlacements: piecePlacements,
                      pieces: [...availablePieces, ...placedPieces],
                      onPieceRemoved: onPieceRemoved,
                    ),
                  ),
                  const Spacer(),
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
                        onDragEnded: () {
                          setState(() {
                            draggingPiece = null;
                          });
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