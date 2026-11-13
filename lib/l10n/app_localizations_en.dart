// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Up2048';

  @override
  String get homeSubtitle =>
      'Swipe to slide and merge tiles. Pick a difficulty.';

  @override
  String get statsButton => 'Stats';

  @override
  String get settingsButton => 'Settings';

  @override
  String get howToPlayButton => 'How to play';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyVeryHard => 'Very Hard';

  @override
  String get taglineEasy => '5×5 board with plenty of help';

  @override
  String get taglineMedium => 'The classic 4×4 experience';

  @override
  String get taglineHard => 'Clutter, extra tiles, mean spawns';

  @override
  String get taglineVeryHard => 'Stones plus hostile spawns';

  @override
  String badgeBoard(int size) {
    return '$size×$size board';
  }

  @override
  String badgeGoal(int target) {
    return 'Goal $target';
  }

  @override
  String badgeStones(int count) {
    return '$count stones';
  }

  @override
  String get badgeMeanSpawns => 'Mean spawns';

  @override
  String badgeExtraTile(int n) {
    return 'Extra tile every $n';
  }

  @override
  String get badgeNoUndo => 'No undo';

  @override
  String badgeUndo(int n) {
    return 'Undo ×$n';
  }

  @override
  String bestScoreLine(int score, int tile) {
    return 'Best $score · Best tile $tile';
  }

  @override
  String get notPlayedYet => 'Not played yet';

  @override
  String get continueButton => 'Continue';

  @override
  String get newGameButton => 'New game';

  @override
  String get playButton => 'Play';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrationSubtitle => 'Haptic feedback on merges and game over';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get reduceMotionSubtitle => 'Skip slide, merge and spawn animations';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get resetData => 'Reset data';

  @override
  String get resetDataSubtitle => 'Clear saves, statistics and settings';

  @override
  String get resetConfirmTitle => 'Reset all data?';

  @override
  String get resetConfirmContent =>
      'This deletes every saved game, all statistics and your settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get careerPoints => 'Career points';

  @override
  String get gamesPlayed => 'Games played';

  @override
  String get wins => 'Wins';

  @override
  String get winRate => 'Win rate';

  @override
  String get bestScore => 'Best score';

  @override
  String get bestTile => 'Best tile';

  @override
  String get totalMoves => 'Total moves';

  @override
  String get howToPlayTitle => 'How to play';

  @override
  String get difficultiesTitle => 'Difficulties';

  @override
  String get step1Title => 'Swipe or use arrow keys';

  @override
  String get step1Body => 'All tiles slide in that direction.';

  @override
  String get step2Title => 'Equal tiles merge';

  @override
  String get step2Body => 'Two 2s become a 4, and the merged value is scored.';

  @override
  String get step3Title => 'Each tile merges once';

  @override
  String get step3Body => '[2, 2, 2, 2] sliding left gives [4, 4], not 8.';

  @override
  String get step4Title => 'Reach the goal tile';

  @override
  String get step4Body =>
      'The target value wins the game — you can keep playing.';

  @override
  String get step5Title => 'No moves left, game over';

  @override
  String get step5Body => 'Stones split lines, so plan around them.';

  @override
  String get newGameConfirmTitle => 'Start a new game?';

  @override
  String get newGameConfirmContent => 'Your current progress will be lost.';

  @override
  String get tooltipNewGame => 'New game';

  @override
  String get scoreLabel => 'SCORE';

  @override
  String get movesLabel => 'MOVES';

  @override
  String get bestLabel => 'BEST';

  @override
  String undoLabel(String count) {
    return 'Undo ($count)';
  }

  @override
  String hintLabel(int count) {
    return 'Hint ($count)';
  }

  @override
  String removeLabel(int count) {
    return 'Remove ($count)';
  }

  @override
  String get cancelLabel => 'Cancel';

  @override
  String resultWinTitle(int tile) {
    return 'You made $tile!';
  }

  @override
  String get gameOverTitle => 'Game over';

  @override
  String scoreLine(int score) {
    return 'Score: $score';
  }

  @override
  String movesLine(int moves) {
    return 'Moves: $moves';
  }

  @override
  String bestTileLine(int tile) {
    return 'Best tile: $tile';
  }

  @override
  String get keepGoing => 'Keep going';

  @override
  String tileSemantics(int value, int row, int col) {
    return 'Tile $value, row $row, column $col';
  }

  @override
  String stoneSemantics(int row, int col) {
    return 'Stone, row $row, column $col';
  }
}
