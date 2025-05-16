import 'dart:math';
import '../models/piece.dart';
import '../models/board_position.dart';

class StartingPiecePlacement {
  final List<ChockABlockPiece> allPieces;
  final Random random = Random();

  static const int BOARD_ROWS = 5;
  static const int BOARD_COLS = 11;
  static const int MIN_PIECE_SIZE = 3;
  static const int MAX_ATTEMPTS = 100;

  StartingPiecePlacement(this.allPieces);

  ChockABlockPiece selectAndPlaceInitialPiece() {
    int randomIndex = random.nextInt(allPieces.length);
    ChockABlockPiece selectedPiece = allPieces[randomIndex];
    int rotations = random.nextInt(4);
    bool shouldFlip = random.nextInt(2) == 1;

    for (int i = 0; i < rotations; i++) {
      selectedPiece.rotateRight();
    }
    if (shouldFlip) {
      selectedPiece.flipPiece();
    }

    BoardPosition validPosition = findValidPositionRandomly(selectedPiece);

    selectedPiece.position = validPosition;
    selectedPiece.isStartingPiece = true;
    return selectedPiece;
  }

  BoardPosition findValidPositionRandomly(ChockABlockPiece piece) {
    int attempts = 0;
    while (attempts < MAX_ATTEMPTS) {
      // Step 1: Take a random position
      int randomRow = random.nextInt(BOARD_ROWS);
      int randomCol = random.nextInt(BOARD_COLS);
      BoardPosition position = BoardPosition(randomRow, randomCol);

      // Step 2: Check if it fits there (no part outside the board)
      if (!doesPieceFitOnBoard(piece, position)) {
        attempts++;
        continue;
      }

      // Step 3: Checks for if it causes an unsolvable problem
      if (causesSmallIsolatedRegions(piece, position)) {
        attempts++;
        continue;
      }

      if (piece.id == 'clifford' && isProblematicCliffordPlacement(piece, position)) {
        attempts++;
        continue;
      }

      if (piece.id == 'ray' && isProblematicRayPlacement(piece, position)) {
        attempts++;
        continue;
      }

      if (piece.id == 'benny' && isProblematicBennyPlacement(piece, position)) {
        attempts++;
        continue;
      }

      return position;
    }

    int pieceHeight = getPieceHeight(piece);
    int pieceWidth = getPieceWidth(piece);

    if (piece.id == 'ray') {
      return BoardPosition(1, 4);
    } else if (piece.id == 'benny') {
      return BoardPosition(1, 3);
    } else {
      return BoardPosition(
          random.nextInt(BOARD_ROWS - pieceHeight),
          random.nextInt(BOARD_COLS - pieceWidth)
      );
    }
  }

  int getPieceHeight(ChockABlockPiece piece) {
    return piece.pattern.length;
  }

  int getPieceWidth(ChockABlockPiece piece) {
    int maxWidth = 0;
    for (var row in piece.pattern) {
      maxWidth = max(maxWidth, row.length);
    }
    return maxWidth;
  }

  bool doesPieceFitOnBoard(ChockABlockPiece piece, BoardPosition position) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;
          if (boardRow < 0 || boardRow >= BOARD_ROWS ||
              boardCol < 0 || boardCol >= BOARD_COLS) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool causesSmallIsolatedRegions(ChockABlockPiece piece, BoardPosition position) {
    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    simulatePlacePiece(boardState, piece, position);

    List<List<int>> connectedGroups = identifyConnectedEmptyRegions(boardState);

    for (var group in connectedGroups) {
      if (group.length < MIN_PIECE_SIZE) {
        return true;
      }
    }
    return false;
  }

  bool isProblematicCliffordPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'clifford') return false;

    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    simulatePlacePiece(boardState, piece, position);

    bool isVertical = getPieceHeight(piece) > getPieceWidth(piece);

    // Case 1: Vertical clifford along right edge
    if (isVertical && position.col >= BOARD_COLS - 2) {
      for (int r = 0; r < BOARD_ROWS; r++) {
        if (r >= position.row && r < position.row + getPieceHeight(piece))
          continue;
        if (position.col + getPieceWidth(piece) - 1 < BOARD_COLS &&
            !boardState[r][position.col + getPieceWidth(piece) - 1]) {
          return true;
        }
      }
    }
    // Case 2: Vertical clifford along left edge
    if (isVertical && position.col <= 1) {
      for (int r = 0; r < BOARD_ROWS; r++) {
        if (r >= position.row && r < position.row + getPieceHeight(piece))
          continue;
        if (position.col > 0 && !boardState[r][position.col - 1]) {
          return true;
        }
      }
    }
    // Case 3: Horizontal clifford along bottom edge
    if (!isVertical && position.row >= BOARD_ROWS - 2) {
      for (int c = 0; c < BOARD_COLS; c++) {
        if (c >= position.col && c < position.col + getPieceWidth(piece))
          continue;
        if (position.row + getPieceHeight(piece) - 1 < BOARD_ROWS &&
            !boardState[position.row + getPieceHeight(piece) - 1][c]) {
          return true;
        }
      }
    }
    // Case 4: Horizontal clifford along top edge
    if (!isVertical && position.row <= 1) {
      for (int c = 0; c < BOARD_COLS; c++) {
        if (c >= position.col && c < position.col + getPieceWidth(piece))
          continue;
        if (position.row > 0 && !boardState[position.row - 1][c]) {
          return true;
        }
      }
    }
    return false;
  }

  bool isProblematicRayPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'ray') return false;

    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    simulatePlacePiece(boardState, piece, position);

    bool isVertical = isRayVertical(piece);
    // Case 1: Vertical ray along right edge
    if (isVertical && position.col >= BOARD_COLS - 2) {
      return true;
    }
    // Case 2: Vertical ray along left edge
    if (isVertical && position.col <= 1) {
      return true;
    }
    // Case 3: Horizontal ray along bottom edge
    if (!isVertical && position.row >= BOARD_ROWS - 2) {
      return true;
    }
    // Case 4: Horizontal ray along top edge
    if (!isVertical && position.row <= 1) {
      return true;
    }
    return false;
  }

  bool isRayVertical(ChockABlockPiece piece) {
    return getPieceHeight(piece) > getPieceWidth(piece);
  }

  bool isProblematicBennyPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'benny') return false;
    if (position.row == 0 && position.col == 0) return true;
    int pieceWidth = getPieceWidth(piece);
    if (position.row == 0 && position.col + pieceWidth >= BOARD_COLS) return true;
    int pieceHeight = getPieceHeight(piece);
    if (position.row + pieceHeight >= BOARD_ROWS && position.col == 0) return true;
    if (position.row + pieceHeight >= BOARD_ROWS && position.col + pieceWidth >= BOARD_COLS) return true;
    return false;
  }

  void simulatePlacePiece(List<List<bool>> boardState, ChockABlockPiece piece, BoardPosition position) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;
          if (boardRow >= 0 && boardRow < BOARD_ROWS && boardCol >= 0 && boardCol < BOARD_COLS) {
            boardState[boardRow][boardCol] = true;
          }
        }
      }
    }
  }

  List<List<int>> identifyConnectedEmptyRegions(List<List<bool>> boardState) {
    List<List<bool>> visited = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));
    List<List<int>> connectedGroups = [];

    for (int row = 0; row < BOARD_ROWS; row++) {
      for (int col = 0; col < BOARD_COLS; col++) {
        if (!boardState[row][col] && !visited[row][col]) {
          List<int> group = [];
          floodFill(boardState, visited, row, col, group);
          connectedGroups.add(group);
        }
      }
    }
    return connectedGroups;
  }

  void floodFill(List<List<bool>> boardState, List<List<bool>> visited,
      int row, int col, List<int> group) {
    if (row < 0 || row >= BOARD_ROWS || col < 0 || col >= BOARD_COLS ||
        boardState[row][col] || visited[row][col]) {
      return;
    }

    visited[row][col] = true;
    group.add(row * BOARD_COLS + col);
    List<List<int>> directions = [
      [-1, 0], [0, -1], [0, 1], [1, 0]
    ];
    for (var dir in directions) {
      floodFill(boardState, visited, row + dir[0], col + dir[1], group);
    }
  }
}