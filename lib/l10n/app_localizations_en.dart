// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get gameTitle => 'Neon Snake Escape';

  @override
  String get levelCompletedDialogTitle => 'LEVEL COMPLETED!';

  @override
  String get timeLabel => 'Time:';

  @override
  String get difficultyLabel => 'Difficulty:';

  @override
  String get nextLevelButton => 'NEXT LEVEL';

  @override
  String get hourWarningMessage => '1 HOUR PASSED! TAKE A BREAK?';

  @override
  String loadingLevelMessage(int levelNumber) {
    return 'Preparing Level $levelNumber...';
  }

  @override
  String get gameOverTitle => 'GAME OVER';

  @override
  String gameOverStats(int levelNumber, String time) {
    return 'Level $levelNumber - Time: $time';
  }

  @override
  String get restartButton => 'RESTART';

  @override
  String panelLevelTitle(int levelNumber) {
    return 'LEVEL $levelNumber';
  }

  @override
  String get statTotal => 'TOTAL';

  @override
  String get statTime => 'TIME';

  @override
  String get statRemaining => 'LEFT';

  @override
  String get bannerAdPlaceholder => 'AD LOADING...';

  @override
  String get difficultySimple => 'Simple';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyVeryHard => 'Very Hard';

  @override
  String get difficultyNightmare => 'Nightmare';
}
