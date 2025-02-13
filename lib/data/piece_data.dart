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
        color: Colors.blue,
      ),
      ChockABlockPiece(
        id: 'clifford', // Clifford Brown
        pattern: [
          [true, false],
          [true, false],
          [true, true],
          [true, false],
        ],
        color: const Color(0xFFD51C1C),
      ),
      ChockABlockPiece(
        id: 'louis', // Louis Armstrong
        pattern: [
          [false, true, true],
          [true, true, false],
          [false, true, false],
        ],
        color: const Color(0xFF5A1CD5),
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
        color: const Color(0xFF49D610),
      ),
      ChockABlockPiece(
        id: 'betty', // Betty Carter
        pattern: [
          [false, true],
          [true, true],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFFF324E9),
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
        color: const Color(0xFF10D67D),
      ),
      ChockABlockPiece(
        id: 'ray', // Ray Charles
        pattern: [
          [true, true],
          [true, false],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFF0057AE),
      ),
      ChockABlockPiece(
        id: 'ronnie', // Ronnie Cuber
        pattern: [
          [true, false],
          [true, true],
          [true, true],
        ],
        color: const Color(0xFF4135B6),
      ),
      ChockABlockPiece(
        id: 'benny', // Benny Goodman
        pattern: [
          [true, false, false],
          [true, false, false],
          [true, true, true],
        ],
        color: const Color(0xFFFBCD14),
      ),
    ];
  }
}