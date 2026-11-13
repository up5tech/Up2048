import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Up2048'**
  String get appTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to slide and merge tiles. Pick a difficulty.'**
  String get homeSubtitle;

  /// No description provided for @statsButton.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsButton;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// No description provided for @howToPlayButton.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlayButton;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyVeryHard.
  ///
  /// In en, this message translates to:
  /// **'Very Hard'**
  String get difficultyVeryHard;

  /// No description provided for @taglineEasy.
  ///
  /// In en, this message translates to:
  /// **'5×5 board with plenty of help'**
  String get taglineEasy;

  /// No description provided for @taglineMedium.
  ///
  /// In en, this message translates to:
  /// **'The classic 4×4 experience'**
  String get taglineMedium;

  /// No description provided for @taglineHard.
  ///
  /// In en, this message translates to:
  /// **'Clutter, extra tiles, mean spawns'**
  String get taglineHard;

  /// No description provided for @taglineVeryHard.
  ///
  /// In en, this message translates to:
  /// **'Stones plus hostile spawns'**
  String get taglineVeryHard;

  /// No description provided for @badgeBoard.
  ///
  /// In en, this message translates to:
  /// **'{size}×{size} board'**
  String badgeBoard(int size);

  /// No description provided for @badgeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal {target}'**
  String badgeGoal(int target);

  /// No description provided for @badgeStones.
  ///
  /// In en, this message translates to:
  /// **'{count} stones'**
  String badgeStones(int count);

  /// No description provided for @badgeMeanSpawns.
  ///
  /// In en, this message translates to:
  /// **'Mean spawns'**
  String get badgeMeanSpawns;

  /// No description provided for @badgeExtraTile.
  ///
  /// In en, this message translates to:
  /// **'Extra tile every {n}'**
  String badgeExtraTile(int n);

  /// No description provided for @badgeNoUndo.
  ///
  /// In en, this message translates to:
  /// **'No undo'**
  String get badgeNoUndo;

  /// No description provided for @badgeUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo ×{n}'**
  String badgeUndo(int n);

  /// No description provided for @bestScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Best {score} · Best tile {tile}'**
  String bestScoreLine(int score, int tile);

  /// No description provided for @notPlayedYet.
  ///
  /// In en, this message translates to:
  /// **'Not played yet'**
  String get notPlayedYet;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @newGameButton.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGameButton;

  /// No description provided for @playButton.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on merges and game over'**
  String get vibrationSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @reduceMotionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip slide, merge and spawn animations'**
  String get reduceMotionSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @resetData.
  ///
  /// In en, this message translates to:
  /// **'Reset data'**
  String get resetData;

  /// No description provided for @resetDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear saves, statistics and settings'**
  String get resetDataSubtitle;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This deletes every saved game, all statistics and your settings.'**
  String get resetConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @careerPoints.
  ///
  /// In en, this message translates to:
  /// **'Career points'**
  String get careerPoints;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games played'**
  String get gamesPlayed;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get winRate;

  /// No description provided for @bestScore.
  ///
  /// In en, this message translates to:
  /// **'Best score'**
  String get bestScore;

  /// No description provided for @bestTile.
  ///
  /// In en, this message translates to:
  /// **'Best tile'**
  String get bestTile;

  /// No description provided for @totalMoves.
  ///
  /// In en, this message translates to:
  /// **'Total moves'**
  String get totalMoves;

  /// No description provided for @howToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlayTitle;

  /// No description provided for @difficultiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Difficulties'**
  String get difficultiesTitle;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Swipe or use arrow keys'**
  String get step1Title;

  /// No description provided for @step1Body.
  ///
  /// In en, this message translates to:
  /// **'All tiles slide in that direction.'**
  String get step1Body;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Equal tiles merge'**
  String get step2Title;

  /// No description provided for @step2Body.
  ///
  /// In en, this message translates to:
  /// **'Two 2s become a 4, and the merged value is scored.'**
  String get step2Body;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Each tile merges once'**
  String get step3Title;

  /// No description provided for @step3Body.
  ///
  /// In en, this message translates to:
  /// **'[2, 2, 2, 2] sliding left gives [4, 4], not 8.'**
  String get step3Body;

  /// No description provided for @step4Title.
  ///
  /// In en, this message translates to:
  /// **'Reach the goal tile'**
  String get step4Title;

  /// No description provided for @step4Body.
  ///
  /// In en, this message translates to:
  /// **'The target value wins the game — you can keep playing.'**
  String get step4Body;

  /// No description provided for @step5Title.
  ///
  /// In en, this message translates to:
  /// **'No moves left, game over'**
  String get step5Title;

  /// No description provided for @step5Body.
  ///
  /// In en, this message translates to:
  /// **'Stones split lines, so plan around them.'**
  String get step5Body;

  /// No description provided for @newGameConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new game?'**
  String get newGameConfirmTitle;

  /// No description provided for @newGameConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Your current progress will be lost.'**
  String get newGameConfirmContent;

  /// No description provided for @tooltipNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get tooltipNewGame;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get scoreLabel;

  /// No description provided for @movesLabel.
  ///
  /// In en, this message translates to:
  /// **'MOVES'**
  String get movesLabel;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get bestLabel;

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo ({count})'**
  String undoLabel(String count);

  /// No description provided for @hintLabel.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count})'**
  String hintLabel(int count);

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove ({count})'**
  String removeLabel(int count);

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @resultWinTitle.
  ///
  /// In en, this message translates to:
  /// **'You made {tile}!'**
  String resultWinTitle(int tile);

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOverTitle;

  /// No description provided for @scoreLine.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreLine(int score);

  /// No description provided for @movesLine.
  ///
  /// In en, this message translates to:
  /// **'Moves: {moves}'**
  String movesLine(int moves);

  /// No description provided for @bestTileLine.
  ///
  /// In en, this message translates to:
  /// **'Best tile: {tile}'**
  String bestTileLine(int tile);

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @tileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Tile {value}, row {row}, column {col}'**
  String tileSemantics(int value, int row, int col);

  /// No description provided for @stoneSemantics.
  ///
  /// In en, this message translates to:
  /// **'Stone, row {row}, column {col}'**
  String stoneSemantics(int row, int col);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
