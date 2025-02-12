import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceData {
  static List<ChockABlockPiece> getAllPieces() {
    return [
      ChockABlockPiece(
        id: 'ella',
        pattern: [
          [true, false],
          [true, false],
          [true, true],
        ],
        color: const Color(0xFFEA1B91),
      ),
      ChockABlockPiece(
        id: 'billie',
        pattern: [
          [true, true],
          [true, false],
        ],
        color: Colors.blue,
      ),
      ChockABlockPiece(
        id: 'clifford',
        pattern: [
          [true, false],
          [true, false],
          [true, true],
          [true, false],
        ],
        color: const Color(0xFFD51C1C),
      ),
      ChockABlockPiece(
        id: 'louis',
        pattern: [
          [false, true, true],
          [true, true, false],
          [false, true, false],
        ],
        color: const Color(0xFF5A1CD5),
      ),
      ChockABlockPiece(
        id: 'nina',
        pattern: [
          [true, false],
          [true, true],
          [false, true],
        ],
        color: const Color(0xFFF3F024),
      ),
      ChockABlockPiece(
        id: 'nat',
        pattern: [
          [false, true, false],
          [true, true, true],
        ],
        color: const Color(0xFF49D610),
      ),
      ChockABlockPiece(
        id: 'betty',
        pattern: [
          [false, true],
          [true, true],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFFF324E9),
      ),
      ChockABlockPiece(
        id: 'charlie',
        pattern: [
          [true, false, false],
          [true, true, false],
          [false, true, true],
        ],
        color: const Color(0xFFF39224),
      ),
      ChockABlockPiece(
        id: 'dizzy',
        pattern: [
          [true, true],
          [true, false],
          [true, true],
        ],
        color: const Color(0xFF10D67D),
      ),
      ChockABlockPiece(
        id: 'ray',
        pattern: [
          [true, true],
          [true, false],
          [true, false],
          [true, false],
        ],
        color: const Color(0xFF0057AE),
      ),
      ChockABlockPiece(
        id: 'ronnie',
        pattern: [
          [true, false],
          [true, true],
          [true, true],
        ],
        color: const Color(0xFF4135B6),
      ),
      ChockABlockPiece(
        id: 'benny',
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