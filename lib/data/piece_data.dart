import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceData {
  static List<ChockABlockPiece> getAllPieces() {
    return [
      ChockABlockPiece(
        id: 'ella', // Ella Fitzgerald
        pattern: [
          [true, false],
          [true, false],
          [true, true],
        ],
        color: const Color(0xFFEA1B91),
      ),
      ChockABlockPiece(
        id: 'billie', // Billie Holiday
        pattern: [
          [true, true],
          [true, false],
        ],
        color: const Color(0xFF2196F3),
      ),
      ChockABlockPiece(
        id: 'clifford', // Clifford Brown
        pattern: [
          [true, false],
          [true, false],
          [true, true],
          [true, false],
        ],
        color: const Color(0xFFC72300),
      ),
      ChockABlockPiece(
        id: 'louis', // Louis Armstrong
        pattern: [
          [false, true, true],
          [true, true, false],
          [false, true, false],
        ],
        color: const Color(0xFF9000B8),
      ),
      ChockABlockPiece(
        id: 'nina', // Nina Simone
        pattern: [
          [true, false],
          [true, true],
          [false, true],
        ],
        color: const Color(0xFFF3F024),
      ),
      ChockABlockPiece(
        id: 'nat', // Nat King Cole
        pattern: [
          [false, true, false],
          [true, true, true],
        ],
        color: const Color(0xFF51F211),
      ),
      ChockABlockPiece(
        id: 'betty', // Betty Carter
        pattern: [
          [false, true],
          [true, true],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFFFFA2FF),
      ),
      ChockABlockPiece(
        id: 'charlie', // Charlie Parker
        pattern: [
          [true, false, false],
          [true, true, false],
          [false, true, true],
        ],
        color: const Color(0xFFF39224),
      ),
      ChockABlockPiece(
        id: 'dizzy', // Dizzy Gillespie
        pattern: [
          [true, true],
          [true, false],
          [true, true],
        ],
        color: const Color(0xFFA8E60E),
      ),
      ChockABlockPiece(
        id: 'ray', // Ray Charles
        pattern: [
          [true, true],
          [true, false],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFF01F09C),
      ),
      ChockABlockPiece(
        id: 'ronnie', // Ronnie Cuber
        pattern: [
          [true, false],
          [true, true],
          [true, true],
        ],
        color: const Color(0xFF0041C2),
      ),
      ChockABlockPiece(
        id: 'benny', // Benny Goodman
        pattern: [
          [true, false, false],
          [true, false, false],
          [true, true, true],
        ],
        color: const Color(0xFF907BD9),
      ),
    ];
  }
}