import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('tr'),
  ];

  /// Oyunun ana başlığı
  ///
  /// In tr, this message translates to:
  /// **'Neon Yılan Kaçış'**
  String get gameTitle;

  /// Bölüm bittiğinde çıkan dialog başlığı
  ///
  /// In tr, this message translates to:
  /// **'LEVEL TAMAMLANDI!'**
  String get levelCompletedDialogTitle;

  /// İstatistik panelindeki süre etiketi
  ///
  /// In tr, this message translates to:
  /// **'Süre:'**
  String get timeLabel;

  /// İstatistik panelindeki zorluk etiketi
  ///
  /// In tr, this message translates to:
  /// **'Zorluk:'**
  String get difficultyLabel;

  /// Bir sonraki levele geçiş butonu metni
  ///
  /// In tr, this message translates to:
  /// **'SONRAKİ LEVEL'**
  String get nextLevelButton;

  /// Uzun süre oynayınca çıkan uyarı mesajı
  ///
  /// In tr, this message translates to:
  /// **'1 SAAT OLDU! MOLA VER?'**
  String get hourWarningMessage;

  /// Level yüklenirken gösterilen mesaj. {levelNumber} bir parametredir.
  ///
  /// In tr, this message translates to:
  /// **'Level {levelNumber} Hazırlanıyor...'**
  String loadingLevelMessage(int levelNumber);

  /// Canlar bittiğinde çıkan başlık
  ///
  /// In tr, this message translates to:
  /// **'OYUN BİTTİ'**
  String get gameOverTitle;

  /// Oyun bitti ekranındaki istatistikler. İki parametre alır.
  ///
  /// In tr, this message translates to:
  /// **'Level {levelNumber} - Süre: {time}'**
  String gameOverStats(int levelNumber, String time);

  /// Oyunu yeniden başlatma butonu
  ///
  /// In tr, this message translates to:
  /// **'BAŞA DÖN'**
  String get restartButton;

  /// Üst paneldeki level başlığı
  ///
  /// In tr, this message translates to:
  /// **'LEVEL {levelNumber}'**
  String panelLevelTitle(int levelNumber);

  /// Toplam süre istatistik etiketi
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM'**
  String get statTotal;

  /// Bölüm süresi istatistik etiketi
  ///
  /// In tr, this message translates to:
  /// **'SÜRE'**
  String get statTime;

  /// Kalan yılan sayısı istatistik etiketi
  ///
  /// In tr, this message translates to:
  /// **'KALAN'**
  String get statRemaining;

  /// Reklam yüklenirken gösterilen yer tutucu metin
  ///
  /// In tr, this message translates to:
  /// **'REKLAM YÜKLENİYOR...'**
  String get bannerAdPlaceholder;

  /// No description provided for @difficultySimple.
  ///
  /// In tr, this message translates to:
  /// **'Basit'**
  String get difficultySimple;

  /// No description provided for @difficultyEasy.
  ///
  /// In tr, this message translates to:
  /// **'Kolay'**
  String get difficultyEasy;

  /// No description provided for @difficultyNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get difficultyNormal;

  /// No description provided for @difficultyHard.
  ///
  /// In tr, this message translates to:
  /// **'Zor'**
  String get difficultyHard;

  /// No description provided for @difficultyVeryHard.
  ///
  /// In tr, this message translates to:
  /// **'Çok Zor'**
  String get difficultyVeryHard;

  /// No description provided for @difficultyNightmare.
  ///
  /// In tr, this message translates to:
  /// **'Kabus'**
  String get difficultyNightmare;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
