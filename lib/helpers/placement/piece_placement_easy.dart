import 'dart:math';
import '../../models/piece.dart';
import '../../models/board_position.dart';

class ThreeStartingPiecePlacement {
  final List<ChockABlockPiece> allPieces;
  final Random random = Random();

  // Board dimensions
  static const int BOARD_ROWS = 5;
  static const int BOARD_COLS = 11;

  // Smallest piece size
  static const int MIN_PIECE_SIZE = 3; // "billie" has 3 cells

  // Maximum attempts to find a valid position
  static const int MAX_ATTEMPTS = 100;

  ThreeStartingPiecePlacement(this.allPieces);

  List<ChockABlockPiece> selectAndPlaceThreeInitialPieces() {
    List<ChockABlockPiece> startingPieces = [];

    // Create a board representation to track placed pieces
    List<List<bool>> boardState = List.generate(
        BOARD_ROWS, (_) => List.generate(BOARD_COLS, (_) => false));

    // Place first piece
    ChockABlockPiece firstPiece = _selectAndPlacePiece(boardState);
    startingPieces.add(firstPiece);

    // Update board state with the first piece
    simulatePlacePiece(boardState, firstPiece, firstPiece.position!);

    // Place second piece, avoiding overlap with the first
    ChockABlockPiece secondPiece = _selectAndPlacePiece(boardState);
    startingPieces.add(secondPiece);

    // Update board state with the second piece
    simulatePlacePiece(boardState, secondPiece, secondPiece.position!);

    // Place third piece, avoiding overlap with the first two
    ChockABlockPiece thirdPiece = _selectAndPlacePiece(boardState);
    startingPieces.add(thirdPiece);

    return startingPieces;
  }

  ChockABlockPiece _selectAndPlacePiece(List<List<bool>> currentBoardState) {
    // Select random piece from the available pieces
    List<ChockABlockPiece> availablePieces = List.from(allPieces);
    availablePieces.shuffle(random);

    // Try each piece until we find one that works
    for (ChockABlockPiece selectedPiece in availablePieces) {
      // Skip pieces that are already used as starting pieces
      if (selectedPiece.isStartingPiece) continue;

      // Save the original orientation to restore later
      List<List<bool>> originalPattern = [];
      for (var row in selectedPiece.pattern) {
        originalPattern.add(List.from(row));
      }

      // Try different orientations
      for (int rotations = 0; rotations < 4; rotations++) {
        // Apply rotations - reset to original pattern first
        selectedPiece.resetOrientation();
        for (int i = 0; i < rotations; i++) {
          selectedPiece.rotateRight();
        }

        // Try with and without flipping
        for (int flipAttempt = 0; flipAttempt < 2; flipAttempt++) {
          if (flipAttempt == 1) {
            selectedPiece.flipPiece();
          }

          // Find a valid position
          BoardPosition? validPosition = findValidPositionWithExistingPieces(
              selectedPiece, currentBoardState);

          if (validPosition != null) {
            // Set the position and mark as starting piece
            selectedPiece.position = validPosition;
            selectedPiece.isStartingPiece = true;

            return selectedPiece;
          }
        }
      }

      // Restore the original pattern orientation
      selectedPiece.resetOrientation();
    }

    // Fallback if no piece works
    return selectFallbackPiece(currentBoardState);
  }

  // Find a valid position with existing pieces on the board
  BoardPosition? findValidPositionWithExistingPieces(
      ChockABlockPiece piece, List<List<bool>> currentBoardState) {
    int attempts = 0;

    while (attempts < MAX_ATTEMPTS) {
      // Step 1: Take a random position
      int randomRow = random.nextInt(BOARD_ROWS);
      int randomCol = random.nextInt(BOARD_COLS);
      BoardPosition position = BoardPosition(randomRow, randomCol);

      // Step 2: Check if it fits on the board
      if (!doesPieceFitOnBoard(piece, position)) {
        attempts++;
        continue;
      }

      // Step 3: Check if it overlaps with existing pieces
      if (doesOverlapWithExistingPieces(piece, position, currentBoardState)) {
        attempts++;
        continue;
      }

      // Step 4: Check if it causes an unsolvable problem
      // Create a temporary board with this new piece
      List<List<bool>> tempBoardState = List.generate(
          BOARD_ROWS, (r) => List.generate(BOARD_COLS, (c) => currentBoardState[r][c]));
      simulatePlacePiece(tempBoardState, piece, position);

      // With three pieces, we need to be less strict about isolated regions,
      // as more of the board will be occupied
      if (countEmptyCells(tempBoardState) < MIN_PIECE_SIZE) {
        attempts++;
        continue;
      }

      // Check for small isolated regions, but be more permissive with 3 pieces
      if (hasVerySmallIsolatedRegions(tempBoardState)) {
        attempts++;
        continue;
      }

      // Specific checks for problematic pieces - only for first two pieces
      // By the third piece, we're already quite constrained
      int placedPiecesCount = countPlacedPieces(currentBoardState);
      if (placedPiecesCount < 2) {
        if (piece.id == 'clifford' && isProblematicCliffordPlacement(piece, position, tempBoardState)) {
          attempts++;
          continue;
        }

        if (piece.id == 'ray' && isProblematicRayPlacement(piece, position, tempBoardState)) {
          attempts++;
          continue;
        }

        if (piece.id == 'benny' && isProblematicBennyPlacement(piece, position, tempBoardState)) {
          attempts++;
          continue;
        }
      }

      // If we get here, the position is valid!
      return position;
    }

    // If no valid position found after maximum attempts
    return null;
  }

  // Count how many pieces have been placed on the board
  int countPlacedPieces(List<List<bool>> boardState) {
    int count = 0;
    for (int r = 0; r < BOARD_ROWS; r++) {
      for (int c = 0; c < BOARD_COLS; c++) {
        if (boardState[r][c]) {
          count++;
        }
      }
    }
    // This is an approximation - divide by average piece size (5)
    return count ~/ 5;
  }

  // Count empty cells on the board
  int countEmptyCells(List<List<bool>> boardState) {
    int count = 0;
    for (int r = 0; r < BOARD_ROWS; r++) {
      for (int c = 0; c < BOARD_COLS; c++) {
        if (!boardState[r][c]) {
          count++;
        }
      }
    }
    return count;
  }

  // Check for very small isolated regions (1 cell)
  bool hasVerySmallIsolatedRegions(List<List<bool>> boardState) {
    // Get connected regions of empty cells
    List<List<int>> connectedGroups = identifyConnectedEmptyRegions(boardState);

    // With three pieces, only check for single-cell regions
    for (var group in connectedGroups) {
      if (group.length == 1) { // Just extremely small regions
        return true;
      }
    }

    return false;
  }

  // Check if a piece overlaps with existing pieces on the board
  bool doesOverlapWithExistingPieces(
      ChockABlockPiece piece, BoardPosition position, List<List<bool>> boardState) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          // Check if within bounds and if cell is already occupied
          if (boardRow >= 0 && boardRow < BOARD_ROWS &&
              boardCol >= 0 && boardCol < BOARD_COLS &&
              boardState[boardRow][boardCol]) {
            return true; // Overlap found
          }
        }
      }
    }
    return false;
  }

  // Fallback piece selection when no piece fits well
  ChockABlockPiece selectFallbackPiece(List<List<bool>> currentBoardState) {
    // Find the smallest piece available
    ChockABlockPiece? smallest;
    int smallestSize = 999;

    for (var piece in allPieces) {
      if (piece.isStartingPiece) continue; // Skip already used pieces

      int pieceSize = countActiveCells(piece);
      if (pieceSize < smallestSize) {
        smallest = piece;
        smallestSize = pieceSize;
      }
    }

    // If all pieces are used (shouldn't happen), take the first one
    if (smallest == null) {
      smallest = allPieces.firstWhere((p) => !p.isStartingPiece, orElse: () => allPieces.first);
    }

    // Save original orientation
    smallest.resetOrientation();

    // For the third piece, we're less picky - just find any valid spot
    for (int row = 0; row < BOARD_ROWS; row++) {
      for (int col = 0; col < BOARD_COLS; col++) {
        BoardPosition position = BoardPosition(row, col);

        if (!doesOverlapWithExistingPieces(smallest, position, currentBoardState) &&
            doesPieceFitOnBoard(smallest, position)) {

          smallest.position = position;
          smallest.isStartingPiece = true;
          return smallest;
        }
      }
    }

    // Last resort - try different rotations
    for (int rotation = 0; rotation < 4; rotation++) {
      smallest.resetOrientation();
      for (int r = 0; r < rotation; r++) {
        smallest.rotateRight();
      }

      for (int row = 0; row < BOARD_ROWS; row++) {
        for (int col = 0; col < BOARD_COLS; col++) {
          BoardPosition position = BoardPosition(row, col);

          if (!doesOverlapWithExistingPieces(smallest, position, currentBoardState) &&
              doesPieceFitOnBoard(smallest, position)) {

            smallest.position = position;
            smallest.isStartingPiece = true;
            return smallest;
          }
        }
      }
    }

    // This is almost impossible to reach with 3 pieces,
    // but just in case, force a solution
    smallest.resetOrientation();
    smallest.position = BoardPosition(0, 0);
    smallest.isStartingPiece = true;
    return smallest;
  }

  // Helper to count active cells in a piece
  int countActiveCells(ChockABlockPiece piece) {
    int count = 0;
    for (var row in piece.pattern) {
      for (var cell in row) {
        if (cell) count++;
      }
    }
    return count;
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

  bool isProblematicCliffordPlacement(ChockABlockPiece piece, BoardPosition position, List<List<bool>> boardState) {
    if (piece.id != 'clifford') return false;

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
  bool isProblematicRayPlacement(ChockABlockPiece piece, BoardPosition position, List<List<bool>> boardState) {
    if (piece.id != 'ray') return false;

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
  bool isProblematicBennyPlacement(ChockABlockPiece piece, BoardPosition position, List<List<bool>> boardState) {
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