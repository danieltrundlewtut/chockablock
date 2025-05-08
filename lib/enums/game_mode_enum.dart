enum GameMode {
  classic,
  timeAttack,
  moveLimit
}

extension GameModeExtension on GameMode {
  String get name {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.timeAttack:
        return 'Time Attack';
      case GameMode.moveLimit:
        return 'Move Limit';
    }
  }
}