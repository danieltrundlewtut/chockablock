import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import '../data/piece_data.dart';
import '../enums/game_difficulty_enum.dart';
import '../enums/game_mode_enum.dart';
import '../helpers/placement/piece_placement_easy.dart';
import '../helpers/placement/piece_placement_hard.dart';
import '../helpers/placement/piece_placement_medi.dart';
import '../models/board_position.dart';
import '../models/piece.dart';
import '../helpers/puzzle_read_write.dart';
import '../widgets/buttons/in_game_menu_button_widget.dart';
import '../widgets/buttons/restart_button_widget.dart';
import '../widgets/subMenus/in_game_menu_widget.dart';
import '../widgets/subMenus/setup_menu_widget.dart';
import '../widgets/subMenus/win_menu_widget.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/pieces_interface_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final GameDifficulty difficulty;
  final List<ChockABlockPiece>? selectedPieces;
  final Map<String, dynamic>? savedPuzzleData;

  const GameScreen({
    super.key,
    this.gameMode = GameMode.classic,
    this.difficulty = GameDifficulty.hard,
    this.selectedPieces,
    this.savedPuzzleData,
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

  // Dev mode properties
  bool isDevMode = false;
  int seed = DateTime.now().millisecondsSinceEpoch;
  int moveCount = 0;
  int filledCells = 0;
  DateTime? startTime;
  Map<String, dynamic> puzzleData = {};
  List<ChockABlockPiece> startingPieces = [];

  // Stopwatch for timing puzzle completion
  Stopwatch stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    availablePieces = PieceData.getAllPieces();

    // Set seed from saved puzzle data if available
    if (widget.savedPuzzleData != null && widget.savedPuzzleData!.containsKey('seed')) {
      seed = widget.savedPuzzleData!['seed'];
    }

    // Only initialize the piece generator if we're not loading a saved puzzle
    if (widget.savedPuzzleData == null) {
      _initializePieceGenerator();
    }

    startTime = DateTime.now();
    stopwatch.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.savedPuzzleData != null) {
        _loadSavedPuzzle();
      } else {
        _placeInitialPieces();
      }
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

    startingPieces = [];

    for (var piece in initialPieces) {
      if (piece.position != null) {
        piece.isStartingPiece = true;
        startingPieces.add(piece);
        onPiecePlaced(
            piece,
            piece.position!.row,
            piece.position!.col,
            isInitialPlacement: true
        );
      }
    }

    // Calculate initial filled cells
    _calculateFilledCells();

    // Initialize puzzle data with starting information
    _initializePuzzleData();
  }

  void _loadSavedPuzzle() {
    try {
      // Clear any existing pieces
      placedPieces = [];
      startingPieces = [];

      // Configure the pieces based on the saved data
      PuzzleManager.configurePiecesFromPuzzleData(
          widget.savedPuzzleData!,
          availablePieces
      );

      // Place the starting pieces on the board
      for (var piece in availablePieces) {
        if (piece.isStartingPiece && piece.position != null) {
          startingPieces.add(piece);
          onPiecePlaced(
              piece,
              piece.position!.row,
              piece.position!.col,
              isInitialPlacement: true
          );
        }
      }

      // Calculate initial filled cells
      _calculateFilledCells();

      // Initialize puzzle data with starting information
      _initializePuzzleData();

    } catch (e) {
      print('Error loading saved puzzle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading puzzle: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateFilledCells() {
    filledCells = 0;
    List<List<bool>> boardGrid = List.generate(
        5, (_) => List.generate(11, (_) => false)
    );

    for (var pieceWidget in placedPieces) {
      final piece = pieceWidget.piece;
      if (piece.position != null) {
        for (int row = 0; row < piece.pattern.length; row++) {
          for (int col = 0; col < piece.pattern[row].length; col++) {
            if (piece.pattern[row][col]) {
              final boardRow = piece.position!.row + row;
              final boardCol = piece.position!.col + col;

              if (boardRow >= 0 && boardRow < 5 &&
                  boardCol >= 0 && boardCol < 11) {
                boardGrid[boardRow][boardCol] = true;
              }
            }
          }
        }
      }
    }

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 11; col++) {
        if (boardGrid[row][col]) {
          filledCells++;
        }
      }
    }
  }

  void _initializePuzzleData() {
    puzzleData = {
      'seed': seed,
      'startingPieces': startingPieces.map((piece) => {
        'id': piece.id,
        'row': piece.position!.row,
        'col': piece.position!.col,
        'rotation': piece.rotationCount,
        'isFlipped': piece.isFlipped,
      }).toList(),
      'filledCells': filledCells,
    };
  }

  void _updateSizes() {
    boardWidth = ((MediaQuery.of(context).size.width) * 0.6);
    cellSize = boardWidth / 11;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSizes();
  }

  void onPiecePlaced(ChockABlockPiece piece, int row, int col, {bool isInitialPlacement = false}) {
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

        // Increment move count only if it's not an initial placement
        if (!isInitialPlacement) {
          moveCount++;
        }
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
        stopwatch.stop();
        _recordSolutionData();
        _showWinMenu();
      }
    });
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    setState(() {
      placedPieces.removeWhere((widget) => widget.piece.id == piece.id);
      if (!availablePieces.any((p) => p.id == piece.id)) {
        availablePieces.add(piece);

        // If piece is not a starting piece, increment move count
        if (!piece.isStartingPiece) {
          moveCount++;
        }
      }
    });
  }

  void _recordSolutionData() {
    final duration = stopwatch.elapsed;

    // Get all non-starting pieces that have been placed
    final List<ChockABlockPiece> placedNonStartingPieces = [];
    for (var placedWidget in placedPieces) {
      final piece = placedWidget.piece;
      if (!piece.isStartingPiece) {
        placedNonStartingPieces.add(piece);
      }
    }

    // Create the puzzle data using the PuzzleManager
    puzzleData = PuzzleManager.createPuzzleData(
      seed: seed,
      startingPieces: startingPieces,
      placedPieces: placedNonStartingPieces,
      filledCells: filledCells,
      timeMs: duration.inMilliseconds,
      moves: moveCount,
    );

    if (isDevMode) {
      // Only save data if this is NOT a pre-stored puzzle
      if (widget.savedPuzzleData == null) {
        PuzzleManager.savePuzzleData(context, puzzleData);
      } else {
        // If it's a pre-stored puzzle, just show a success message without saving
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Puzzle completed! (Pre-stored puzzle not recorded)'),
              duration: Duration(seconds: 2),
            ),
          );
        });
      }
    }
  }

  void _toggleDevMode() {
    setState(() {
      isDevMode = !isDevMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDevMode ? 'Dev Mode Enabled' : 'Dev Mode Disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showGameMenu() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GameMenu(
          onRestartPuzzle: restartCurrentPuzzle,
          onSetupGame: setupNewGame,
        );
      },
    );
  }

  void resetGame() {
    stopwatch.reset();
    stopwatch.start();
    moveCount = 0;

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

      // If we're using a saved puzzle, reload it, otherwise generate a new one
      if (widget.savedPuzzleData != null) {
        _loadSavedPuzzle();
      } else {
        seed = DateTime.now().millisecondsSinceEpoch; // Generate new seed
        _initializePieceGenerator();
        _placeInitialPieces();
      }
    });
  }

  void restartCurrentPuzzle() {
    stopwatch.reset();
    stopwatch.start();
    moveCount = 0;

    setState(() {
      List<ChockABlockPiece> piecesToRemove = [];
      for (var placedPiece in placedPieces) {
        if (!placedPiece.piece.isStartingPiece) {
          piecesToRemove.add(placedPiece.piece);
        }
      }

      for (var piece in piecesToRemove) {
        placedPieces.removeWhere((placedPiece) => placedPiece.piece.id == piece.id);

        // Reset the piece's orientation and position
        piece.resetOrientation();
        piece.position = null;

        // Add back to available pieces if not already there
        if (!availablePieces.any((p) => p.id == piece.id)) {
          availablePieces.add(piece);
        }
      }
    });
  }

  void setupNewGame() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SetupGameMenu(
          onBack: () => Navigator.of(dialogContext).pop(),
        );
      },
    ).then((_) { });
  }

  bool _checkWinCondition() {
    List<List<bool>> boardGrid = List.generate(
        5, (_) => List.generate(11, (_) => false)
    );

    for (var pieceWidget in placedPieces) {
      final piece = pieceWidget.piece;
      if (piece.position != null) {
        for (int row = 0; row < piece.pattern.length; row++) {
          for (int col = 0; col < piece.pattern[row].length; col++) {
            if (piece.pattern[row][col]) {
              final boardRow = piece.position!.row + row;
              final boardCol = piece.position!.col + col;

              if (boardRow >= 0 && boardRow < 5 &&
                  boardCol >= 0 && boardCol < 11) {
                boardGrid[boardRow][boardCol] = true;
              }
            }
          }
        }
      }
    }

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 11; col++) {
        if (!boardGrid[row][col]) {
          return false;
        }
      }
    }

    return true;
  }

  void _showWinMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WinMenu(
            onNewGame: () {
              Navigator.of(context).pop();
              resetGame();
            },
            onSetupGame: () {
              setupNewGame();
            }
        );
      },
    );
  }

  Widget _buildDevModeButton() {
    return Positioned(
      top: 10,
      left: 70, // Position right next to the menu button
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDevMode ? Colors.red.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: IconButton(
          icon: const Icon(Icons.code),
          color: Colors.white,
          onPressed: _toggleDevMode,
          tooltip: 'Dev Mode',
        ),
      ),
    );
  }

  Widget _buildDevModePanel() {
    if (!isDevMode) return const SizedBox.shrink();

    return Positioned(
      top: 70, // Position below the menu button
      left: 10,
      child: Container(
        width: 60, // Narrow panel
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _compactDevButton(
              icon: Icons.bar_chart,
              tooltip: 'Stats',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Current Puzzle Stats'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seed: $seed'),
                        Text('Difficulty: ${widget.difficulty.toString().split('.').last}'),
                        Text('Moves: $moveCount'),
                        Text('Time: ${stopwatch.elapsed.inSeconds}s'),
                        Text('Filled Cells: $filledCells'),
                        Text('Total Cells: 55'),
                        Text('Completion: ${(filledCells / 55 * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _compactDevButton(
              icon: Icons.folder_open,
              tooltip: 'View Puzzles',
              onPressed: () => PuzzleManager.showAllPuzzlesDialog(context),
            ),
            const SizedBox(height: 10),
            _compactDevButton(
              icon: Icons.copy,
              tooltip: 'Copy Data',
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(PuzzleManager.savedPuzzles)
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All puzzles copied to clipboard')),
                );
              },
            ),
            const SizedBox(height: 10),
            // Debug button for JSON file
            _compactDevButton(
              icon: Icons.bug_report,
              tooltip: 'Debug JSON',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check console for debug info')),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              'M: $moveCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              'T: ${stopwatch.elapsed.inSeconds}s',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              'F: $filledCells/55',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactDevButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 22, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
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
                  if (isDevMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Moves: $moveCount | Time: ${stopwatch.elapsed.inSeconds}s | Filled: $filledCells/55',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),

              GameMenuButton(
                onPressed: _showGameMenu,
              ),

              _buildDevModeButton(),

              Positioned(
                top: 10, // Position from top
                right: 10, // Position from right
                child: RestartButton(
                  onPressed: resetGame,
                ),
              ),

              _buildDevModePanel(),
            ],
          ),
        ),
      ),
    );
  }
}