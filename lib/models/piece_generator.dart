import '../models/piece.dart';

abstract class PieceGenerator {
  List<ChockABlockPiece> pieces;

  PieceGenerator(this.pieces);

  List<ChockABlockPiece> placeInitialPieces();
}