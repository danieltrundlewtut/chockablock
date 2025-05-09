import 'package:flutter/material.dart';
import '../data/piece_data.dart';
import '../enums/game_difficulty_enum.dart';
import '../enums/game_mode_enum.dart';
import '../helpers/placement/piece_placement_easy.dart';
import '../helpers/placement/piece_placement_hard.dart';
import '../helpers/placement/piece_placement_medi.dart';
import '../models/board_position.dart';
import '../models/piece.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/pieces_interface_widget.dart';
import '../widgets/restartbutton_widget.dart';
import '../widgets/win_menu_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final GameDifficulty difficulty;
  final List<ChockABlockPiece>? selectedPieces;

  const GameScreen({
    super.key,
    this.gameMode = GameMode.classic,
    this.difficulty = GameDifficulty.easy,
    this.selectedPieces,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<ChockABlockPiece> availablePieces = [];
  List<PieceWidget> placedPieces = [];
  ChockABlockPiece? draggingPiece;
  late double boardWidth;
  late double cellSize;
  late dynamic pieceGenerator;

  @override
  void initState() {
    super.initState();
    availablePieces = PieceData.getAllPieces();
    _initializePieceGenerator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placeInitialPieces();
    });
  }

  void _initializePieceGenerator() {
    switch (widget.difficulty) {
      case GameDifficulty.easy:
        pieceGenerator = ThreeStartingPiecePlacement(List.from(availablePieces));
        break;
      case GameDifficulty.hard:
        pieceGenerator = OneStartingPiecePlacement(List.from(availablePieces));
        break;
      default:
        pieceGenerator = TwoStartingPiecePlacement(List.from(availablePieces));
        break;
    }
  }

  void _placeInitialPieces() {
    List<ChockABlockPiece> initialPieces = [];
    switch (widget.difficulty) {
      case GameDifficulty.easy:
        initialPieces = pieceGenerator.selectAndPlaceThreeInitialPieces();
        break;
      case GameDifficulty.hard:
        initialPieces = pieceGenerator.selectAndPlaceInitialPiece();
        break;
      default:
        initialPieces = pieceGenerator.selectAndPlaceTwoInitialPieces();
        break;
    }

    for (var piece in initialPieces) {
      if (piece.position != null) {
        onPiecePlaced(
            piece,
            piece.position!.row,
            piece.position!.col
        );
      }
    }
  }

  void _updateSizes() {
    boardWidth = ((MediaQuery
        .of(context)
        .size
        .width) * 0.6);
    cellSize = boardWidth / 11;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSizes();
  }

  void onPiecePlaced(ChockABlockPiece piece, int row, int col) {
    BoardPosition position = BoardPosition(row, col);
    setState(() {
      piece.position = position;

      final pieceWidget = PieceWidget(
        key: ValueKey(piece.id),
        piece: piece,
        cellSize: cellSize,
        position: position,
        onTap: () => onPieceRemoved(piece),
        onDragStart: (touchPosition, draggedPiece) {},
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_checkWinCondition()) {
        _showWinMenu();
      }
    });
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    setState(() {
      placedPieces.removeWhere((widget) => widget.piece.id == piece.id);
      if (!availablePieces.any((p) => p.id == piece.id)) {
        availablePieces.add(piece);
      }
    });
  }

  void resetGame() {
    setState(() {
      // First, collect all pieces (both placed and available)
      List<ChockABlockPiece> allPieces = [];

      // Add available pieces
      allPieces.addAll(availablePieces);

      // Add placed pieces
      for (var placedPiece in placedPieces) {
        ChockABlockPiece piece = placedPiece.piece;
        if (!allPieces.any((p) => p.id == piece.id)) {
          allPieces.add(piece);
        }
      }

      // Reset all pieces to their initial state
      for (var piece in allPieces) {
        piece.resetOrientation(); // Reset to original pattern
        piece.position = null;
        piece.isStartingPiece = false;
      }

      // Clear the current state
      placedPieces = [];
      availablePieces = allPieces; // All pieces are now available

      _initializePieceGenerator();

      _placeInitialPieces();
    });
  }

  // Add this method to your _GameScreenState class to check for win condition
  bool _checkWinCondition() {
    // Create a 2D grid to represent the board (5 rows x 11 columns)
    List<List<bool>> boardGrid = List.generate(
        5, (_) => List.generate(11, (_) => false)
    );

    // Mark all cells covered by pieces
    for (var pieceWidget in placedPieces) {
      final piece = pieceWidget.piece;
      if (piece.position != null) {
        for (int row = 0; row < piece.pattern.length; row++) {
          for (int col = 0; col < piece.pattern[row].length; col++) {
            if (piece.pattern[row][col]) {
              final boardRow = piece.position!.row + row;
              final boardCol = piece.position!.col + col;

              // Make sure we're within board boundaries
              if (boardRow >= 0 && boardRow < 5 &&
                  boardCol >= 0 && boardCol < 11) {
                boardGrid[boardRow][boardCol] = true;
              }
            }
          }
        }
      }
    }

    // Check if all cells are filled
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 11; col++) {
        if (!boardGrid[row][col]) {
          return false; // Found an empty cell
        }
      }
    }

    return true; // All cells are filled
  }

  void _showWinMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WinMenu(
          onNewGame: () {
            Navigator.of(context).pop(); // Close the dialog
            resetGame();
          },
          onSetupGame: () {
            Navigator.of(context).pop(); // Close the dialog
            // Setup game functionality can be implemented later
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 10),
                  Center(
                    child: GameBoard(
                      cellSize: cellSize,
                      placedPieces: placedPieces,
                      onDragUpdate: (position) {},
                      onPiecePlaced: onPiecePlaced,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 64.0, vertical: 16.0),
                    child: Center(
                      child: PiecesInterface(
                        pieces: availablePieces,
                        placedPieces: placedPieces,
                        cellSize: cellSize * 0.393,
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

              // Restart button - positioned on top layer
              Positioned(
                top: 10, // Position from top
                right: 10, // Position from right
                child: RestartButton(
                  onPressed: resetGame,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}