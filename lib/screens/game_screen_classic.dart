import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import '../data/piece_data.dart';
import '../enums/game_difficulty_enum.dart';
import '../enums/game_mode_enum.dart';
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
    this.difficulty = GameDifficulty.easy,
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

  // Game state variables
  bool isGameStarted = false;
  bool isPreparing = true;
  bool isDevMode = false;

  // Puzzle data
  int seed = DateTime.now().millisecondsSinceEpoch;
  int moveCount = 0;
  int filledCells = 0;
  List<ChockABlockPiece> startingPieces = [];
  Map<String, dynamic> puzzleData = {};

  // Stopwatch for timing puzzle completion
  Stopwatch stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    availablePieces = PieceData.getAllPieces();

    // If there's saved puzzle data, load it directly
    if (widget.savedPuzzleData != null) {
      seed = widget.savedPuzzleData!['seed'] ?? seed;
      isPreparing = false;
      isGameStarted = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedPuzzle();
        stopwatch.start();
      });
    } else {
      // Otherwise, start in preparation mode with all pieces available
      isPreparing = true;
      isGameStarted = false;
      // Don't start the stopwatch yet - wait until the user clicks "Start Game"
    }
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

  void _startGame() {
    // Check if there are any pieces on the board
    if (placedPieces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place at least one piece on the board'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Mark all currently placed pieces as starting pieces
      for (var placedPieceWidget in placedPieces) {
        final piece = placedPieceWidget.piece;
        piece.isStartingPiece = true;
        startingPieces.add(piece);
      }

      // Update game state
      isPreparing = false;
      isGameStarted = true;
      moveCount = 0; // Reset the move count

      // Generate seed if not already set
      seed = DateTime.now().millisecondsSinceEpoch;

      // Calculate initial filled cells
      _calculateFilledCells();

      // Initialize puzzle data
      _initializePuzzleData();

      // Start the stopwatch
      stopwatch.start();
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game started! These pieces are now set as starting pieces.'),
        duration: Duration(seconds: 2),
      ),
    );
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
    // Check if this is a move (piece is already on the board and being moved)
    bool isMove = false;
    if (!isInitialPlacement && piece.position != null) {
      isMove = (piece.position!.row != row || piece.position!.col != col);
    }

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

        // Increment move count only if game has started and it's not an initial placement
        if (isGameStarted && !isInitialPlacement) {
          moveCount++;
        }
      } else {
        final index = placedPieces.indexWhere((p) => p.piece.id == piece.id);
        if (index != -1) {
          placedPieces[index] = pieceWidget;

          // Count as a move if game has started and piece is being repositioned
          if (isGameStarted && isMove) {
            moveCount++;
          }
        }
      }
      draggingPiece = null;
    });

    // Only check win condition if the game has started
    if (isGameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_checkWinCondition()) {
          stopwatch.stop();
          _recordSolutionData();
          _showWinMenu();
        }
      });
    }
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    // If game hasn't started, allow removing any piece
    // If game has started, only allow removing non-starting pieces
    if (!isGameStarted || !piece.isStartingPiece) {
      setState(() {
        placedPieces.removeWhere((widget) => widget.piece.id == piece.id);
        if (!availablePieces.any((p) => p.id == piece.id)) {
          availablePieces.add(piece);

          // If game has started and piece is not a starting piece, increment move count
          if (isGameStarted && !piece.isStartingPiece) {
            moveCount++;
          }
        }
      });
    } else {
      // Notify user that starting pieces can't be removed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting pieces cannot be removed during the game'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      startingPieces = [];

      // If we're using a saved puzzle, reload it, otherwise reset to preparation mode
      if (widget.savedPuzzleData != null) {
        isGameStarted = true;
        isPreparing = false;
        seed = widget.savedPuzzleData!['seed'] ?? DateTime.now().millisecondsSinceEpoch;
        _loadSavedPuzzle();
        stopwatch.start();
      } else {
        isGameStarted = false;
        isPreparing = true;
        seed = DateTime.now().millisecondsSinceEpoch;
      }
    });
  }

  void restartCurrentPuzzle() {
    stopwatch.reset();
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

      // Restart the stopwatch if we're in a game
      if (isGameStarted) {
        stopwatch.start();
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

  Widget _buildStartGameButton() {
    if (!isPreparing) return const SizedBox.shrink();

    return Positioned(
      top: 10,
      right: 70, // Position left of the restart button
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
        ),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text(''),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: _startGame,
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
                        Text('Game Started: ${isGameStarted ? 'Yes' : 'No'}'),
                        Text('Preparing: ${isPreparing ? 'Yes' : 'No'}'),
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
            if (isGameStarted) ...[
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

    String gameStateText = 'Game not started yet';
    if (isPreparing) {
      gameStateText = 'Set up your starting pieces, then press Start Game';
    } else if (isGameStarted) {
      gameStateText = isDevMode
          ? 'Moves: $moveCount | Time: ${stopwatch.elapsed.inSeconds}s | Filled: $filledCells/55'
          : '';
    }

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
                  if (gameStateText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        gameStateText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),

              GameMenuButton(
                onPressed: _showGameMenu,
              ),

              _buildDevModeButton(),

              _buildStartGameButton(),

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