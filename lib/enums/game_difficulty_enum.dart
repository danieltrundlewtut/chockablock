enum GameDifficulty {
  easy,
  medium,
  hard
}

extension GameDifficultyExtension on GameDifficulty {
  String get name {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }
}