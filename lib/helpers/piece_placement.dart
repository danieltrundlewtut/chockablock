import 'dart:math';
import '../models/piece.dart';
import '../models/board_position.dart';

class StartingPiecePlacement {
  final List<ChockABlockPiece> allPieces;
  final Random random = Random();

  // Board dimensions
  static const int BOARD_ROWS = 5;
  static const int BOARD_COLS = 11;

  // Smallest piece size
  static const int MIN_PIECE_SIZE = 3; // "billie" has 3 cells

  // Maximum attempts to find a valid position
  static const int MAX_ATTEMPTS = 100;

  StartingPiecePlacement(this.allPieces);

  ChockABlockPiece selectAndPlaceInitialPiece() {
    // Select random piece from the available pieces
    int randomIndex = random.nextInt(allPieces.length);
    ChockABlockPiece selectedPiece = allPieces[randomIndex];

    // Apply random orientation
    int rotations = random.nextInt(4); // 0-3 rotations
    bool shouldFlip = random.nextInt(2) == 1; // 50% chance to flip

    // Apply rotations
    for (int i = 0; i < rotations; i++) {
      selectedPiece.rotateRight();
    }

    if (shouldFlip) {
      selectedPiece.flipPiece();
    }

    // Find a good position for the piece using the random approach
    BoardPosition validPosition = findValidPositionRandomly(selectedPiece);

    // Set the position on the piece
    selectedPiece.position = validPosition;
    selectedPiece.isStartingPiece = true;

    return selectedPiece;
  }

  // Find a valid position using random attempts, following the requested steps
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

      // Step 3: Check if it causes an unsolvable problem
      // Note: Only check for 1-2 cell isolated regions, more relaxed check
      if (causesSmallIsolatedRegions(piece, position)) {
        attempts++;
        continue;
      }

      if (piece.id == 'clifford' && isProblematicCliffordPlacement(piece, position)) {
        attempts++;
        continue;
      }

      // Special case for the 'ray' piece
      if (piece.id == 'ray' && isProblematicRayPlacement(piece, position)) {
        attempts++;
        continue;
      }

      // Special case for 'benny' in corners
      if (piece.id == 'benny' && isProblematicBennyPlacement(piece, position)) {
        attempts++;
        continue;
      }

      // If we get here, the position is valid!
      return position;
    }

    // FALLBACK: If we couldn't find a valid position after many attempts,
    // use a safe position that depends on the piece
    int pieceHeight = getPieceHeight(piece);
    int pieceWidth = getPieceWidth(piece);

    // Pick a fallback position based on piece type - different for each piece
    if (piece.id == 'ray') {
      return BoardPosition(1, 4); // Center for ray
    } else if (piece.id == 'benny') {
      return BoardPosition(1, 3); // Away from corners for benny
    } else {
      // For other pieces, try for variety but ensure they fit
      return BoardPosition(
          random.nextInt(BOARD_ROWS - pieceHeight),
          random.nextInt(BOARD_COLS - pieceWidth)
      );
    }
  }

  // Helper to get piece height
  int getPieceHeight(ChockABlockPiece piece) {
    return piece.pattern.length;
  }

  // Helper to get piece width
  int getPieceWidth(ChockABlockPiece piece) {
    int maxWidth = 0;
    for (var row in piece.pattern) {
      maxWidth = max(maxWidth, row.length);
    }
    return maxWidth;
  }

  // Check if the piece fits on the board at the given position
  bool doesPieceFitOnBoard(ChockABlockPiece piece, BoardPosition position) {
    // Detailed check of each cell in the piece
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          // Check if this cell would be off the board
          if (boardRow < 0 || boardRow >= BOARD_ROWS ||
              boardCol < 0 || boardCol >= BOARD_COLS) {
            return false;
          }
        }
      }
    }

    return true;
  }

  // Check for small isolated regions (1-2 cells)
  bool causesSmallIsolatedRegions(ChockABlockPiece piece, BoardPosition position) {
    // Create a board representation to simulate placing the piece
    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    // Place the piece on the simulated board
    simulatePlacePiece(boardState, piece, position);

    // Get connected regions of empty cells
    List<List<int>> connectedGroups = identifyConnectedEmptyRegions(boardState);

    // Only check for very small regions (1-2 cells)
    for (var group in connectedGroups) {
      if (group.length < MIN_PIECE_SIZE) {
        return true;
      }
    }

    return false;
  }

  bool isProblematicCliffordPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'clifford') return false;

    // Create a board representation to simulate placing the piece
    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    // Place the piece on the simulated board
    simulatePlacePiece(boardState, piece, position);

    // Determine orientation
    bool isVertical = getPieceHeight(piece) > getPieceWidth(piece);

    // Case 1: Vertical clifford along right edge
    if (isVertical && position.col >= BOARD_COLS - 2) {
      // Check for isolated cells to the right
      for (int r = 0; r < BOARD_ROWS; r++) {
        if (r >= position.row && r < position.row + getPieceHeight(piece))
          continue; // Skip the clifford itself

        if (position.col + getPieceWidth(piece) - 1 < BOARD_COLS &&
            !boardState[r][position.col + getPieceWidth(piece) - 1]) {
          return true; // Isolated cell found
        }
      }
    }

    // Case 2: Vertical clifford along left edge
    if (isVertical && position.col <= 1) {
      // Check for isolated cells to the left
      for (int r = 0; r < BOARD_ROWS; r++) {
        if (r >= position.row && r < position.row + getPieceHeight(piece))
          continue; // Skip the clifford itself

        if (position.col > 0 && !boardState[r][position.col - 1]) {
          return true; // Isolated cell found
        }
      }
    }

    // Case 3: Horizontal clifford along bottom edge
    if (!isVertical && position.row >= BOARD_ROWS - 2) {
      // Check for isolated cells below
      for (int c = 0; c < BOARD_COLS; c++) {
        if (c >= position.col && c < position.col + getPieceWidth(piece))
          continue; // Skip the clifford itself

        if (position.row + getPieceHeight(piece) - 1 < BOARD_ROWS &&
            !boardState[position.row + getPieceHeight(piece) - 1][c]) {
          return true; // Isolated cell found
        }
      }
    }

    // Case 4: Horizontal clifford along top edge
    if (!isVertical && position.row <= 1) {
      // Check for isolated cells above
      for (int c = 0; c < BOARD_COLS; c++) {
        if (c >= position.col && c < position.col + getPieceWidth(piece))
          continue; // Skip the clifford itself

        if (position.row > 0 && !boardState[position.row - 1][c]) {
          return true; // Isolated cell found
        }
      }
    }

    return false;
  }
  // Special check for the 'ray' piece
  bool isProblematicRayPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'ray') return false;

    // Create a board representation to simulate placing the piece
    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    // Place the piece on the simulated board
    simulatePlacePiece(boardState, piece, position);

    // Check if ray is vertical or horizontal
    bool isVertical = isRayVertical(piece);

    // Problem case 1: Vertical ray along right edge
    if (isVertical && position.col >= BOARD_COLS - 2) {
      return true;
    }

    // Problem case 2: Vertical ray along left edge
    if (isVertical && position.col <= 1) {
      return true;
    }

    // Problem case 3: Horizontal ray along bottom edge
    if (!isVertical && position.row >= BOARD_ROWS - 2) {
      return true;
    }

    // Problem case 4: Horizontal ray along top edge
    if (!isVertical && position.row <= 1) {
      return true;
    }

    return false;
  }

  // Check if ray piece is vertical (based on its pattern)
  bool isRayVertical(ChockABlockPiece piece) {
    // Simple height vs width check
    return getPieceHeight(piece) > getPieceWidth(piece);
  }

  // Special check for 'benny' in corners
  bool isProblematicBennyPlacement(ChockABlockPiece piece, BoardPosition position) {
    if (piece.id != 'benny') return false;

    // Check if benny is in a corner
    // Top-left corner
    if (position.row == 0 && position.col == 0) return true;

    // Top-right corner check (based on piece width)
    int pieceWidth = getPieceWidth(piece);
    if (position.row == 0 && position.col + pieceWidth >= BOARD_COLS) return true;

    // Bottom-left corner check (based on piece height)
    int pieceHeight = getPieceHeight(piece);
    if (position.row + pieceHeight >= BOARD_ROWS && position.col == 0) return true;

    // Bottom-right corner check (based on piece dimensions)
    if (position.row + pieceHeight >= BOARD_ROWS && position.col + pieceWidth >= BOARD_COLS) return true;

    return false;
  }

  // Simulate placing a piece on a board representation
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

  // Identify all connected empty regions on the board
  List<List<int>> identifyConnectedEmptyRegions(List<List<bool>> boardState) {
    // Track visited cells
    List<List<bool>> visited = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    List<List<int>> connectedGroups = [];

    // Find all connected regions of empty cells
    for (int row = 0; row < BOARD_ROWS; row++) {
      for (int col = 0; col < BOARD_COLS; col++) {
        if (!boardState[row][col] && !visited[row][col]) {
          // New connected region found
          List<int> group = [];
          floodFill(boardState, visited, row, col, group);
          connectedGroups.add(group);
        }
      }
    }

    return connectedGroups;
  }

  // Flood fill algorithm to find connected empty cells (orthogonal connections only)
  void floodFill(List<List<bool>> boardState, List<List<bool>> visited,
      int row, int col, List<int> group) {
    // Check bounds and if cell is already filled or visited
    if (row < 0 || row >= BOARD_ROWS || col < 0 || col >= BOARD_COLS ||
        boardState[row][col] || visited[row][col]) {
      return;
    }

    // Mark as visited
    visited[row][col] = true;

    // Add to current group (using a flat index for simplicity)
    group.add(row * BOARD_COLS + col);

    // Check orthogonal neighbors (NOT diagonals since pieces only connect orthogonally)
    List<List<int>> directions = [
      [-1, 0], [0, -1], [0, 1], [1, 0]
    ];

    for (var dir in directions) {
      floodFill(boardState, visited, row + dir[0], col + dir[1], group);
    }
  }
}