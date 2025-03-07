import 'dart:math';
import '../models/piece.dart';
import '../models/board_position.dart';
import 'position_score.dart';

class StartingPiecePlacement {
  final List<ChockABlockPiece> allPieces;
  final Random random = Random();

  StartingPiecePlacement(this.allPieces);

  // Place a random piece on the board avoiding dead spaces
  ChockABlockPiece selectAndPlaceInitialPiece() {
    // Select random piece from the available pieces
    int randomIndex = random.nextInt(allPieces.length);
    ChockABlockPiece selectedPiece = allPieces[randomIndex];

    // Apply random orientation
    int rotations = random.nextInt(4); // 0-3 rotations
    bool shouldFlip = random.nextInt(2) == 1; // 50% chance to flip

    // Clone the piece pattern to avoid modifying the original
    /*selectedPiece = ChockABlockPiece(
      id: selectedPiece.id,
      pattern: List.from(selectedPiece.pattern.map((row) => List.from(row))),
      color: selectedPiece.color,
    );*/

    // Apply rotations
    for (int i = 0; i < rotations; i++) {
      selectedPiece.rotateRight();
    }

    if (shouldFlip) {
      selectedPiece.flipPiece();
    }

    // Find a good position for the piece
    BoardPosition bestPosition = findOptimalPosition(selectedPiece);

    // Set the position on the piece
    selectedPiece.position = bestPosition;

    selectedPiece.isStartingPiece = true;

    return selectedPiece;
  }

  // Find a position that doesn't create dead spaces
  BoardPosition findOptimalPosition(ChockABlockPiece piece) {
    List<BoardPosition> validPositions = getAllValidPositionsFor(piece);

    if (validPositions.isEmpty) {
      // Fallback to a safe position if no valid positions found
      return BoardPosition(2, 5);
    }

    // Score each position based on the "dead space" it might create
    List<PositionScore> scoredPositions = [];

    for (BoardPosition pos in validPositions) {
      double score = evaluatePosition(piece, pos);
      scoredPositions.add(PositionScore(pos, score));
    }

    // Sort by highest score (best positions first)
    scoredPositions.sort((a, b) => b.score.compareTo(a.score));

    // Pick from the top 3 best positions randomly to add variety
    int selectionRange = min(3, scoredPositions.length);
    int randomBestIndex = random.nextInt(selectionRange);

    return scoredPositions[randomBestIndex].position;
  }

  // Get all valid positions for a piece on a 5x11 board
  List<BoardPosition> getAllValidPositionsFor(ChockABlockPiece piece) {
    List<BoardPosition> positions = [];

    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 11; col++) {
        BoardPosition pos = BoardPosition(row, col);
        if (isValidPosition(pos, piece, [])) {
          positions.add(pos);
        }
      }
    }

    return positions;
  }

  // Check if a position is valid for a piece
  bool isValidPosition(BoardPosition position, ChockABlockPiece piece, List<ChockABlockPiece> placedPieces) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          if (boardRow < 0 || boardRow >= 5 ||
              boardCol < 0 || boardCol >= 11) {
            return false;
          }

          for (var placedPiece in placedPieces) {
            if (doPiecesCollide(piece, position, placedPiece)) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  // Check if two pieces collide
  bool doPiecesCollide(ChockABlockPiece piece, BoardPosition position, ChockABlockPiece placedPiece) {
    if (placedPiece.position == null) return false;
    if (placedPiece == piece) return false;

    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          int newRow = position.row + row;
          int newCol = position.col + col;

          for (int pieceX = 0; pieceX < placedPiece.pattern.length; pieceX++) {
            for (int pieceY = 0; pieceY < placedPiece.pattern[pieceX].length; pieceY++) {
              if (placedPiece.pattern[pieceX][pieceY]) {
                int placedRow = placedPiece.position!.row + pieceX;
                int placedCol = placedPiece.position!.col + pieceY;

                if (newRow == placedRow && newCol == placedCol) {
                  return true;
                }
              }
            }
          }
        }
      }
    }
    return false;
  }

  // Evaluate how good a position is (higher score is better)
  double evaluatePosition(ChockABlockPiece piece, BoardPosition position) {
    // Create a board representation to simulate placing the piece
    List<List<bool>> boardState = List.generate(5, (_) => List.generate(11, (_) => false));

    // Place the piece on the simulated board
    simulatePlacePiece(boardState, piece, position);

    // Calculate score based only on dead space factor
    double score = 0.0;

    // Check for isolated cells (dead spaces)
    int isolatedCells = countIsolatedCells(boardState);

    // Heavily penalize positions that create isolated cells
    if (isolatedCells > 0) {
      score -= isolatedCells * 100.0;
    }

    // Add some small randomness to break ties (0.0 to 1.0)
    score += random.nextDouble();

    return score;
  }

  // Simulate placing a piece on a board representation
  void simulatePlacePiece(List<List<bool>> boardState, ChockABlockPiece piece, BoardPosition position) {
    for (int row = 0; row < piece.pattern.length; row++) {
      for (int col = 0; col < piece.pattern[row].length; col++) {
        if (piece.pattern[row][col]) {
          final boardRow = position.row + row;
          final boardCol = position.col + col;

          if (boardRow >= 0 && boardRow < 5 && boardCol >= 0 && boardCol < 11) {
            boardState[boardRow][boardCol] = true;
          }
        }
      }
    }
  }

  // Count isolated single cells that might be unfillable
  int countIsolatedCells(List<List<bool>> boardState) {
    int count = 0;

    // Check each empty cell on the board
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 11; col++) {
        if (!boardState[row][col] && isIsolatedCell(boardState, row, col)) {
          count++;
        }
      }
    }

    return count;
  }

  // Check if a cell is isolated such that no piece could fill it
  bool isIsolatedCell(List<List<bool>> boardState, int row, int col) {
    // If cell already filled, it's not isolated
    if (boardState[row][col]) {
      return false;
    }

    // Count adjacent empty cells (horizontal and vertical only)
    int emptyNeighbors = 0;
    List<List<int>> directions = [
      [0, 1], [1, 0], [0, -1], [-1, 0]
    ];

    for (var dir in directions) {
      int newRow = row + dir[0];
      int newCol = col + dir[1];

      if (newRow >= 0 && newRow < 5 && newCol >= 0 && newCol < 11) {
        if (!boardState[newRow][newCol]) {
          emptyNeighbors++;
        }
      }
    }

    // A cell is potentially problematic if it has 0 or 1 empty neighbors
    // No piece can fill a completely isolated cell (0 neighbors)
    // Very few pieces can fill cells with only 1 neighbor
    return emptyNeighbors <= 1;
  }
}
