// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get gameTitle => 'Neon Yılan Kaçış';

  @override
  String get levelCompletedDialogTitle => 'LEVEL TAMAMLANDI!';

  @override
  String get timeLabel => 'Süre:';

  @override
  String get difficultyLabel => 'Zorluk:';

  @override
  String get nextLevelButton => 'SONRAKİ LEVEL';

  @override
  String get hourWarningMessage => '1 SAAT OLDU! MOLA VER?';

  @override
  String loadingLevelMessage(int levelNumber) {
    return 'Level $levelNumber Hazırlanıyor...';
  }

  @override
  String get gameOverTitle => 'OYUN BİTTİ';

  @override
  String gameOverStats(int levelNumber, String time) {
    return 'Level $levelNumber - Süre: $time';
  }

  @override
  String get restartButton => 'BAŞA DÖN';

  @override
  String panelLevelTitle(int levelNumber) {
    return 'LEVEL $levelNumber';
  }

  @override
  String get statTotal => 'TOPLAM';

  @override
  String get statTime => 'SÜRE';

  @override
  String get statRemaining => 'KALAN';

  @override
  String get bannerAdPlaceholder => 'REKLAM YÜKLENİYOR...';

  @override
  String get difficultySimple => 'Basit';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get difficultyVeryHard => 'Çok Zor';

  @override
  String get difficultyNightmare => 'Kabus';
}
