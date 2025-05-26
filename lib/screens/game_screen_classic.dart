import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/piece_data.dart';
import '../enums/game_mode_enum.dart';
import '../helpers/piece_placement.dart';
import '../models/board_position.dart';
import '../models/piece.dart';
import '../widgets/buttons/in_game_menu_button_widget.dart';
import '../widgets/buttons/restart_button_widget.dart';
import '../widgets/subMenus/in_game_menu_widget.dart';
import '../widgets/subMenus/win_menu_widget.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/pieces_interface_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final List<ChockABlockPiece>? selectedPieces;

  const GameScreen({
    super.key,
    this.gameMode = GameMode.classic,
    this.selectedPieces,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  List<ChockABlockPiece> availablePieces = [];
  List<PieceWidget> placedPieces = [];
  ChockABlockPiece? draggingPiece;
  bool gameWon = false;
  int moveCount = 0;
  DateTime? startTime;
  DateTime? endTime;
  int? finalScore;
  late double boardWidth;
  late double cellSize;
  late StartingPiecePlacement pieceGenerator;

  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  DateTime? _pauseStartTime;
  int _totalPausedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    availablePieces = PieceData.getAllPieces();
    pieceGenerator = StartingPiecePlacement(List.from(availablePieces));

    startTime = DateTime.now();
    moveCount = 0;
    gameWon = false;

    _startGameTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placeInitialPiece();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (gameWon) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeGameTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseGameTimer();
        break;
    }
  }

  void _startGameTimer() {
    if (_isTimerRunning) return;

    _isTimerRunning = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !gameWon) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _pauseGameTimer() {
    if (!_isTimerRunning) return;

    _gameTimer?.cancel();
    _isTimerRunning = false;
    _pauseStartTime = DateTime.now();
  }

  void _resumeGameTimer() {
    if (_isTimerRunning) return;

    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseStartTime!).inSeconds;
      _totalPausedSeconds += pauseDuration;
      _pauseStartTime = null;
    }

    _startGameTimer();
  }

  void _stopGameTimer() {
    _gameTimer?.cancel();
    _isTimerRunning = false;
  }

  void _placeInitialPiece() {
    ChockABlockPiece initialPiece = pieceGenerator.selectAndPlaceInitialPiece();

    if (initialPiece.position != null) {
      onPiecePlaced(
          initialPiece,
          initialPiece.position!.row,
          initialPiece.position!.col
      );
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
    if (gameWon) return;

    BoardPosition newPosition = BoardPosition(row, col);
    bool isPlacedPiece = piece.position != null;
    bool isPositionChanging = false;

    if(isPlacedPiece) {
      BoardPosition oldPosition = piece.position!;

      if (oldPosition.row != row || oldPosition.col != col) {
        isPositionChanging = true;
      }
    }

    setState(() {
      if ((!isPlacedPiece && !piece.isStartingPiece) ||
          (isPlacedPiece && isPositionChanging)) {
        moveCount++;
      }

      piece.position = newPosition;

      final pieceWidget = PieceWidget(
        key: ValueKey(piece.id),
        piece: piece,
        cellSize: cellSize,
        position: newPosition,
        onTap: gameWon ? () {} : () => onPieceRemoved(piece),
        onDragStart: gameWon ? null : (touchPosition, draggedPiece) {},
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
        setState(() {
          gameWon = true;
        });

        endTime = DateTime.now();
        _stopGameTimer();
        finalScore = _calculateScore();
        _showWinMenu();
      }
    });
  }

  void onPieceRemoved(ChockABlockPiece piece) {
    if (gameWon) return;

    if (!piece.isStartingPiece) {
      moveCount++;
    }

    setState(() {
      placedPieces.removeWhere((widget) => widget.piece.id == piece.id);
      if (!availablePieces.any((p) => p.id == piece.id)) {
        availablePieces.add(piece);
      }
    });
  }

  void _showGameMenu() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GameMenu(
          onRestartPuzzle: restartCurrentPuzzle,
        );
      },
    );
  }

  void resetGame() {
    startTime = DateTime.now();
    endTime = null;
    moveCount = 0;
    gameWon = false;
    finalScore = null;

    _elapsedSeconds = 0;
    _totalPausedSeconds = 0;
    _pauseStartTime = null;
    _stopGameTimer();
    _startGameTimer();

    setState(() {
      List<ChockABlockPiece> allPieces = [];
      allPieces.addAll(availablePieces);

      for (var placedPiece in placedPieces) {
        ChockABlockPiece piece = placedPiece.piece;
        if (!allPieces.any((p) => p.id == piece.id)) {
          allPieces.add(piece);
        }
      }

      for (var piece in allPieces) {
        piece.resetOrientation();
        piece.position = null;
        piece.isStartingPiece = false;
      }

      placedPieces = [];
      availablePieces = allPieces;

      pieceGenerator = StartingPiecePlacement(List.from(availablePieces));
      _placeInitialPiece();
    });
  }

  void restartCurrentPuzzle() {
    setState(() {
      List<ChockABlockPiece> piecesToRemove = [];
      for (var placedPiece in placedPieces) {
        if (!placedPiece.piece.isStartingPiece) {
          piecesToRemove.add(placedPiece.piece);
        }
      }

      for (var piece in piecesToRemove) {
        placedPieces.removeWhere((placedPiece) => placedPiece.piece.id == piece.id);

        piece.resetOrientation();
        piece.position = null;

        if (!availablePieces.any((p) => p.id == piece.id)) {
          availablePieces.add(piece);
        }
      }
    });
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

  int _calculateScore() {
    if (startTime == null || endTime == null) return 0;
    final secondsTaken = _elapsedSeconds;

    const int timeMaxBonus = 1000;
    const int timeMinBonus = 60;
    const int bestTime = 60;
    const int worstTime = 360;

    final clampedTime = secondsTaken.clamp(bestTime, worstTime);
    final timeProgress = (clampedTime - bestTime) / (worstTime - bestTime);
    final nonlinearTimeProgress = sqrt(timeProgress);
    final timeBonus = (timeMaxBonus - (nonlinearTimeProgress * (timeMaxBonus - timeMinBonus))).round();

    const int moveMaxBonus = 1000;
    const int moveMinBonus = 50;
    const int bestMoves = 20;
    const int worstMoves = 120;
    final clampedMoves = moveCount.clamp(bestMoves, worstMoves);

    final moveProgress = (clampedMoves - bestMoves) / (worstMoves - bestMoves);
    final nonlinearMoveProgress = sqrt(moveProgress);
    final moveBonus = (moveMaxBonus - (nonlinearMoveProgress * (moveMaxBonus - moveMinBonus))).round();

    return timeBonus + moveBonus;
  }

  void _showWinMenu() {
    endTime = DateTime.now();
    finalScore = _calculateScore();
    gameWon = true;

    final secondsTaken = _elapsedSeconds;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return WinMenu(
          score: finalScore ?? 0,
          moveCount: moveCount,
          secondsTaken: secondsTaken,
          onNewGame: () {
            Navigator.of(context).pop();
            resetGame();
          },
          onDismiss: () {
            Navigator.of(context).pop();
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
                        draggingPiece: gameWon ? null : draggingPiece,
                        onDragStarted: gameWon ? (_) {} : (piece) {
                          setState(() {
                            draggingPiece = piece;
                          });
                        },
                        onDragEnded: gameWon ? (_) {} : (piece) {
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

              GameMenuButton(
                onPressed: _showGameMenu,
              ),

              Positioned(
                top: 10,
                right: 10,
                child: RestartButton(onPressed: resetGame),
              ),
            ],
          ),
        ),
      ),
    );
  }
}