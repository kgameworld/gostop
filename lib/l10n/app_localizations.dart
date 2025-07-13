import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @privacyManagement.
  ///
  /// In en, this message translates to:
  /// **'Privacy Management'**
  String get privacyManagement;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @gameSettings.
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get gameSettings;

  /// No description provided for @animationSettings.
  ///
  /// In en, this message translates to:
  /// **'Animation Settings'**
  String get animationSettings;

  /// No description provided for @animationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation Speed'**
  String get animationSpeed;

  /// No description provided for @slow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get slow;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @instant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get instant;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @consentSettings.
  ///
  /// In en, this message translates to:
  /// **'Consent Settings'**
  String get consentSettings;

  /// No description provided for @downloadData.
  ///
  /// In en, this message translates to:
  /// **'Download Data'**
  String get downloadData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @gameInfo.
  ///
  /// In en, this message translates to:
  /// **'Game Info'**
  String get gameInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @gwang.
  ///
  /// In en, this message translates to:
  /// **'Gwang'**
  String get gwang;

  /// No description provided for @gutt.
  ///
  /// In en, this message translates to:
  /// **'Gutt'**
  String get gutt;

  /// No description provided for @tti.
  ///
  /// In en, this message translates to:
  /// **'Tti'**
  String get tti;

  /// No description provided for @pi.
  ///
  /// In en, this message translates to:
  /// **'Pi'**
  String get pi;

  /// No description provided for @remainingCards.
  ///
  /// In en, this message translates to:
  /// **'Remaining Cards'**
  String get remainingCards;

  /// No description provided for @myTurn.
  ///
  /// In en, this message translates to:
  /// **'My Turn'**
  String get myTurn;

  /// No description provided for @opponentTurn.
  ///
  /// In en, this message translates to:
  /// **'Opponent\'s Turn'**
  String get opponentTurn;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get win;

  /// No description provided for @lose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get lose;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @totalGames.
  ///
  /// In en, this message translates to:
  /// **'Total Games'**
  String get totalGames;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get endGame;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete?'**
  String get deleteConfirm;

  /// No description provided for @deleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Delete Request'**
  String get deleteRequest;

  /// No description provided for @dataDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Data download is complete. It will be sent by email.'**
  String get dataDownloadComplete;

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while updating settings: {error}'**
  String updateError(Object error);

  /// No description provided for @consentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Consent settings have been updated.'**
  String get consentUpdated;

  /// No description provided for @accountDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'If you delete your account, all personal information will be permanently deleted and cannot be recovered.'**
  String get accountDeleteWarning;

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get guestAccount;

  /// No description provided for @guestWarning.
  ///
  /// In en, this message translates to:
  /// **'You are logged in as a guest. Game records are not saved, and all data will be lost if you delete the app. We recommend creating an account.'**
  String get guestWarning;

  /// No description provided for @aiMatch.
  ///
  /// In en, this message translates to:
  /// **'AI Match'**
  String get aiMatch;

  /// No description provided for @twoPlayerMatch.
  ///
  /// In en, this message translates to:
  /// **'2P Match'**
  String get twoPlayerMatch;

  /// No description provided for @onlinePvp.
  ///
  /// In en, this message translates to:
  /// **'Online PvP'**
  String get onlinePvp;

  /// No description provided for @friendMatch.
  ///
  /// In en, this message translates to:
  /// **'Friend Match'**
  String get friendMatch;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get howToPlay;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @remainingCount.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {count}/3'**
  String remainingCount(Object count);

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// No description provided for @inviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Invite Friend'**
  String get inviteFriend;

  /// No description provided for @gameRecord.
  ///
  /// In en, this message translates to:
  /// **'Game Record'**
  String get gameRecord;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @coinPackages.
  ///
  /// In en, this message translates to:
  /// **'Coin Packages'**
  String get coinPackages;

  /// No description provided for @starterPackage.
  ///
  /// In en, this message translates to:
  /// **'Starter Package'**
  String get starterPackage;

  /// No description provided for @coins1000.
  ///
  /// In en, this message translates to:
  /// **'1,000 Coins'**
  String get coins1000;

  /// No description provided for @premiumPackage.
  ///
  /// In en, this message translates to:
  /// **'Premium Package'**
  String get premiumPackage;

  /// No description provided for @coins5000Bonus500.
  ///
  /// In en, this message translates to:
  /// **'5,000 Coins + 500 Bonus'**
  String get coins5000Bonus500;

  /// No description provided for @megaPackage.
  ///
  /// In en, this message translates to:
  /// **'Mega Package'**
  String get megaPackage;

  /// No description provided for @coins15000Bonus2000.
  ///
  /// In en, this message translates to:
  /// **'15,000 Coins + 2,000 Bonus'**
  String get coins15000Bonus2000;

  /// No description provided for @battlePass.
  ///
  /// In en, this message translates to:
  /// **'Battle Pass'**
  String get battlePass;

  /// No description provided for @battlePassSeason1.
  ///
  /// In en, this message translates to:
  /// **'Season 1 Battle Pass'**
  String get battlePassSeason1;

  /// No description provided for @specialReward30days.
  ///
  /// In en, this message translates to:
  /// **'30 Days Special Rewards'**
  String get specialReward30days;

  /// No description provided for @specialItems.
  ///
  /// In en, this message translates to:
  /// **'Special Items'**
  String get specialItems;

  /// No description provided for @goldCardTheme.
  ///
  /// In en, this message translates to:
  /// **'Gold Card Theme'**
  String get goldCardTheme;

  /// No description provided for @specialCardDesign.
  ///
  /// In en, this message translates to:
  /// **'Special Card Design'**
  String get specialCardDesign;

  /// No description provided for @specialAvatar.
  ///
  /// In en, this message translates to:
  /// **'Special Avatar'**
  String get specialAvatar;

  /// No description provided for @uniqueCharacterAvatar.
  ///
  /// In en, this message translates to:
  /// **'Unique Character Avatar'**
  String get uniqueCharacterAvatar;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @adReward.
  ///
  /// In en, this message translates to:
  /// **'Ad Reward'**
  String get adReward;

  /// No description provided for @watchAdReward.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad Reward'**
  String get watchAdReward;

  /// No description provided for @earn50Coins.
  ///
  /// In en, this message translates to:
  /// **'Earn 50 Coins'**
  String get earn50Coins;

  /// No description provided for @remainingCount5.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {count}/5'**
  String remainingCount5(Object count);

  /// No description provided for @purchaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Purchase Confirmation'**
  String get purchaseConfirm;

  /// No description provided for @purchaseItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to purchase this item?'**
  String get purchaseItemConfirm;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Purchase completed!'**
  String get purchaseCompleted;

  /// No description provided for @recentPurchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent Purchase History'**
  String get recentPurchaseHistory;

  /// No description provided for @watchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad'**
  String get watchAd;

  /// No description provided for @watchAdToEarn50.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to earn 50 coins.'**
  String get watchAdToEarn50;

  /// No description provided for @earned50Coins.
  ///
  /// In en, this message translates to:
  /// **'You have earned 50 coins!'**
  String get earned50Coins;

  /// No description provided for @featureRestriction.
  ///
  /// In en, this message translates to:
  /// **'Feature Restriction'**
  String get featureRestriction;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @guestModeRestriction.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode Restriction'**
  String get guestModeRestriction;

  /// No description provided for @guestModePurchaseBlock.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available in guest mode. Please create an account to buy coins and battle pass!'**
  String get guestModePurchaseBlock;

  /// No description provided for @privacyPolicyGlobal.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy applies to all users worldwide.'**
  String get privacyPolicyGlobal;

  /// No description provided for @section1CollectedInfo.
  ///
  /// In en, this message translates to:
  /// **'1. Collected Personal Information'**
  String get section1CollectedInfo;

  /// No description provided for @section1CollectedInfo1.
  ///
  /// In en, this message translates to:
  /// **'• Social login info: email, profile name'**
  String get section1CollectedInfo1;

  /// No description provided for @section1CollectedInfo2.
  ///
  /// In en, this message translates to:
  /// **'• Game play data: score, win/loss record, game stats'**
  String get section1CollectedInfo2;

  /// No description provided for @section1CollectedInfo3.
  ///
  /// In en, this message translates to:
  /// **'• Device info: OS version, app version, device ID'**
  String get section1CollectedInfo3;

  /// No description provided for @section1CollectedInfo4.
  ///
  /// In en, this message translates to:
  /// **'• Usage analytics: play time, feature usage'**
  String get section1CollectedInfo4;

  /// No description provided for @section2Purpose.
  ///
  /// In en, this message translates to:
  /// **'2. Purpose of Collecting Personal Information'**
  String get section2Purpose;

  /// No description provided for @section2Purpose1.
  ///
  /// In en, this message translates to:
  /// **'• Provide game service and account management'**
  String get section2Purpose1;

  /// No description provided for @section2Purpose2.
  ///
  /// In en, this message translates to:
  /// **'• Save game records and analyze statistics'**
  String get section2Purpose2;

  /// No description provided for @section2Purpose3.
  ///
  /// In en, this message translates to:
  /// **'• Customer support and inquiry handling'**
  String get section2Purpose3;

  /// No description provided for @section2Purpose4.
  ///
  /// In en, this message translates to:
  /// **'• Service improvement and new feature development'**
  String get section2Purpose4;

  /// No description provided for @section2Purpose5.
  ///
  /// In en, this message translates to:
  /// **'• Security and fraud prevention'**
  String get section2Purpose5;

  /// No description provided for @section3Retention.
  ///
  /// In en, this message translates to:
  /// **'3. Retention Period of Personal Information'**
  String get section3Retention;

  /// No description provided for @section3Retention1.
  ///
  /// In en, this message translates to:
  /// **'• Until account deletion or legal retention period'**
  String get section3Retention1;

  /// No description provided for @section3Retention2.
  ///
  /// In en, this message translates to:
  /// **'• Retained for 30 days after service suspension (restorable)'**
  String get section3Retention2;

  /// No description provided for @section3Retention3.
  ///
  /// In en, this message translates to:
  /// **'• Additional retention as required by law'**
  String get section3Retention3;

  /// No description provided for @section4Provision.
  ///
  /// In en, this message translates to:
  /// **'4. Provision of Personal Information to Third Parties'**
  String get section4Provision;

  /// No description provided for @section4Provision1.
  ///
  /// In en, this message translates to:
  /// **'We do not provide personal information to third parties without explicit user consent.'**
  String get section4Provision1;

  /// No description provided for @section4Provision2.
  ///
  /// In en, this message translates to:
  /// **'Provided only in the following cases:'**
  String get section4Provision2;

  /// No description provided for @section4Provision3.
  ///
  /// In en, this message translates to:
  /// **'• Service providers: Supabase (data storage), Google/Apple (social login)\n• Legal requirements: court order, law enforcement request\n• Service protection: fraud prevention, security response'**
  String get section4Provision3;

  /// No description provided for @section5Rights.
  ///
  /// In en, this message translates to:
  /// **'5. User Rights'**
  String get section5Rights;

  /// No description provided for @section5Rights1.
  ///
  /// In en, this message translates to:
  /// **'Users have the following rights:'**
  String get section5Rights1;

  /// No description provided for @section5Rights2.
  ///
  /// In en, this message translates to:
  /// **'• View and edit personal information'**
  String get section5Rights2;

  /// No description provided for @section5Rights3.
  ///
  /// In en, this message translates to:
  /// **'• Request deletion of personal information'**
  String get section5Rights3;

  /// No description provided for @section5Rights4.
  ///
  /// In en, this message translates to:
  /// **'• Request suspension of personal information processing'**
  String get section5Rights4;

  /// No description provided for @section5Rights5.
  ///
  /// In en, this message translates to:
  /// **'• Data portability request\n• Withdraw consent'**
  String get section5Rights5;

  /// No description provided for @section6Security.
  ///
  /// In en, this message translates to:
  /// **'6. Data Security'**
  String get section6Security;

  /// No description provided for @section6Security1.
  ///
  /// In en, this message translates to:
  /// **'We take the following security measures to protect personal information:'**
  String get section6Security1;

  /// No description provided for @section6Security2.
  ///
  /// In en, this message translates to:
  /// **'• Data encryption (in transit and at rest)'**
  String get section6Security2;

  /// No description provided for @section6Security3.
  ///
  /// In en, this message translates to:
  /// **'• Access control and restriction'**
  String get section6Security3;

  /// No description provided for @section6Security4.
  ///
  /// In en, this message translates to:
  /// **'• Regular security audits\n• Staff security training'**
  String get section6Security4;

  /// No description provided for @section7International.
  ///
  /// In en, this message translates to:
  /// **'7. International Data Transfer'**
  String get section7International;

  /// No description provided for @section7International1.
  ///
  /// In en, this message translates to:
  /// **'User data may be processed in the following countries:'**
  String get section7International1;

  /// No description provided for @section7International2.
  ///
  /// In en, this message translates to:
  /// **'• Korea: main server and data storage'**
  String get section7International2;

  /// No description provided for @section7International3.
  ///
  /// In en, this message translates to:
  /// **'• USA: Supabase cloud service'**
  String get section7International3;

  /// No description provided for @section7International4.
  ///
  /// In en, this message translates to:
  /// **'• Others: social login provider servers\nAll data transfers are subject to appropriate safeguards.'**
  String get section7International4;

  /// No description provided for @section8Children.
  ///
  /// In en, this message translates to:
  /// **'8. Children\'s Privacy Protection'**
  String get section8Children;

  /// No description provided for @section8Children1.
  ///
  /// In en, this message translates to:
  /// **'Our service is intended for users aged 13 and older.'**
  String get section8Children1;

  /// No description provided for @section8Children2.
  ///
  /// In en, this message translates to:
  /// **'We do not knowingly collect personal information from children under 13.'**
  String get section8Children2;

  /// No description provided for @section8Children3.
  ///
  /// In en, this message translates to:
  /// **'We do not process children\'s information without parental/guardian consent.'**
  String get section8Children3;

  /// No description provided for @section9Cookies.
  ///
  /// In en, this message translates to:
  /// **'9. Cookies and Tracking Technologies'**
  String get section9Cookies;

  /// No description provided for @section9Cookies1.
  ///
  /// In en, this message translates to:
  /// **'We use the following technologies:'**
  String get section9Cookies1;

  /// No description provided for @section9Cookies2.
  ///
  /// In en, this message translates to:
  /// **'• Essential cookies: basic functions required for service\n• Analytics cookies: usage statistics for service improvement'**
  String get section9Cookies2;

  /// No description provided for @section9Cookies3.
  ///
  /// In en, this message translates to:
  /// **'• Users can manage cookies in browser settings.'**
  String get section9Cookies3;

  /// No description provided for @section10Changes.
  ///
  /// In en, this message translates to:
  /// **'10. Changes to Privacy Policy'**
  String get section10Changes;

  /// No description provided for @section10Changes1.
  ///
  /// In en, this message translates to:
  /// **'We may change this policy as needed.'**
  String get section10Changes1;

  /// No description provided for @section10Changes2.
  ///
  /// In en, this message translates to:
  /// **'If there are important changes:'**
  String get section10Changes2;

  /// No description provided for @section10Changes3.
  ///
  /// In en, this message translates to:
  /// **'• In-app announcements\n• Email notifications (for registered users)\n• Previous policy provided for 30 days after change'**
  String get section10Changes3;

  /// No description provided for @section11Inquiries.
  ///
  /// In en, this message translates to:
  /// **'11. Inquiries and Reports'**
  String get section11Inquiries;

  /// No description provided for @section11Inquiries1.
  ///
  /// In en, this message translates to:
  /// **'For personal information inquiries, contact:'**
  String get section11Inquiries1;

  /// No description provided for @section11Inquiries2.
  ///
  /// In en, this message translates to:
  /// **'• Email: privacy@gostop-game.com'**
  String get section11Inquiries2;

  /// No description provided for @section11Inquiries3.
  ///
  /// In en, this message translates to:
  /// **'• Address: [Company address]'**
  String get section11Inquiries3;

  /// No description provided for @section11Inquiries4.
  ///
  /// In en, this message translates to:
  /// **'• Phone: [Customer center number]'**
  String get section11Inquiries4;

  /// No description provided for @section11Inquiries5.
  ///
  /// In en, this message translates to:
  /// **'• Response time: within 3 business days'**
  String get section11Inquiries5;

  /// No description provided for @section12ExerciseRights.
  ///
  /// In en, this message translates to:
  /// **'12. How to Exercise Your Rights'**
  String get section12ExerciseRights;

  /// No description provided for @section12ExerciseRights1.
  ///
  /// In en, this message translates to:
  /// **'To exercise your personal information rights:'**
  String get section12ExerciseRights1;

  /// No description provided for @section12ExerciseRights2.
  ///
  /// In en, this message translates to:
  /// **'• In-app settings > Privacy management'**
  String get section12ExerciseRights2;

  /// No description provided for @section12ExerciseRights3.
  ///
  /// In en, this message translates to:
  /// **'• Request by email: privacy@gostop-game.com'**
  String get section12ExerciseRights3;

  /// No description provided for @section12ExerciseRights4.
  ///
  /// In en, this message translates to:
  /// **'• Processed after identity verification (ID or other proof)'**
  String get section12ExerciseRights4;

  /// No description provided for @section12ExerciseRights5.
  ///
  /// In en, this message translates to:
  /// **'• Results notified within 30 days'**
  String get section12ExerciseRights5;

  /// No description provided for @importantNotice.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantNotice;

  /// No description provided for @privacyPolicyNotice.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy is a basic global policy. Depending on your region (EU, California, Brazil, etc.), you may have additional privacy rights. We will provide region-specific policies step by step.'**
  String get privacyPolicyNotice;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: December 2024'**
  String get lastUpdated;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @battlepass.
  ///
  /// In en, this message translates to:
  /// **'Battle Pass'**
  String get battlepass;

  /// No description provided for @battlepassSeason1.
  ///
  /// In en, this message translates to:
  /// **'Season 1 Battle Pass'**
  String get battlepassSeason1;

  /// No description provided for @guestModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode Notice'**
  String get guestModeNotice;

  /// No description provided for @guestModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Purchases are restricted in guest mode. Create an account to access all features.'**
  String get guestModeDescription;

  /// No description provided for @purchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchase Unavailable'**
  String get purchaseUnavailable;

  /// No description provided for @remainingRewards.
  ///
  /// In en, this message translates to:
  /// **'Remaining rewards: {count}'**
  String remainingRewards(Object count);

  /// No description provided for @purchaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Purchase Confirmation'**
  String get purchaseConfirmation;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Do you want to purchase this {itemId}?'**
  String confirmPurchase(Object itemId);

  /// No description provided for @watchAdToEarnCoins.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to earn coins.'**
  String get watchAdToEarnCoins;

  /// No description provided for @featureRestricted.
  ///
  /// In en, this message translates to:
  /// **'Feature Restricted'**
  String get featureRestricted;

  /// No description provided for @recentPurchases.
  ///
  /// In en, this message translates to:
  /// **'Recent Purchases'**
  String get recentPurchases;

  /// No description provided for @gwangBak.
  ///
  /// In en, this message translates to:
  /// **'No Bright'**
  String get gwangBak;

  /// No description provided for @piBak.
  ///
  /// In en, this message translates to:
  /// **'Low Junk'**
  String get piBak;

  /// No description provided for @goBak.
  ///
  /// In en, this message translates to:
  /// **'Go Penalty'**
  String get goBak;

  /// No description provided for @chongtong.
  ///
  /// In en, this message translates to:
  /// **'Perfect Hand'**
  String get chongtong;

  /// No description provided for @godori.
  ///
  /// In en, this message translates to:
  /// **'Bird Trio'**
  String get godori;

  /// No description provided for @blank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get blank;

  /// No description provided for @snap.
  ///
  /// In en, this message translates to:
  /// **'Snap'**
  String get snap;

  /// No description provided for @doubleMatch.
  ///
  /// In en, this message translates to:
  /// **'Double Match'**
  String get doubleMatch;

  /// No description provided for @doubleJunk.
  ///
  /// In en, this message translates to:
  /// **'Double Junk'**
  String get doubleJunk;

  /// No description provided for @sweep.
  ///
  /// In en, this message translates to:
  /// **'Sweep'**
  String get sweep;

  /// No description provided for @shake.
  ///
  /// In en, this message translates to:
  /// **'Shake'**
  String get shake;

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get first;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @player1Win.
  ///
  /// In en, this message translates to:
  /// **'Player 1 Wins!'**
  String get player1Win;

  /// No description provided for @player2Win.
  ///
  /// In en, this message translates to:
  /// **'Player 2 Wins!'**
  String get player2Win;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @scoreVs.
  ///
  /// In en, this message translates to:
  /// **'Score: {score1} vs {score2}'**
  String scoreVs(Object score1, Object score2);

  /// No description provided for @coinEarned.
  ///
  /// In en, this message translates to:
  /// **'🪙 +{coins} coins earned!'**
  String coinEarned(Object coins);

  /// No description provided for @coinLost.
  ///
  /// In en, this message translates to:
  /// **'🪙 {coins} coins lost'**
  String coinLost(Object coins);

  /// No description provided for @lobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get lobby;

  /// No description provided for @selectCardToEat.
  ///
  /// In en, this message translates to:
  /// **'Select a card to eat'**
  String get selectCardToEat;

  /// No description provided for @heundalQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to shake?'**
  String get heundalQuestion;

  /// No description provided for @selectedCard.
  ///
  /// In en, this message translates to:
  /// **'Selected card: {cardName}'**
  String selectedCard(Object cardName);

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @heundal.
  ///
  /// In en, this message translates to:
  /// **'Shake!'**
  String get heundal;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get go;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stop;

  /// No description provided for @myScore.
  ///
  /// In en, this message translates to:
  /// **'Me: {score} pts'**
  String myScore(Object score);

  /// No description provided for @aiScore.
  ///
  /// In en, this message translates to:
  /// **'AI: {score} pts'**
  String aiScore(Object score);

  /// No description provided for @goBonus.
  ///
  /// In en, this message translates to:
  /// **'{multiplier}x'**
  String goBonus(Object multiplier);

  /// No description provided for @heundalStatus.
  ///
  /// In en, this message translates to:
  /// **'Shake!'**
  String get heundalStatus;

  /// No description provided for @bombStatus.
  ///
  /// In en, this message translates to:
  /// **'Bomb!'**
  String get bombStatus;

  /// No description provided for @autoPlay.
  ///
  /// In en, this message translates to:
  /// **'Auto Play'**
  String get autoPlay;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String scoreLabel(Object score);

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get points;

  /// No description provided for @animal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get animal;

  /// No description provided for @junk.
  ///
  /// In en, this message translates to:
  /// **'Junk'**
  String get junk;

  /// No description provided for @ribbon.
  ///
  /// In en, this message translates to:
  /// **'Ribbon'**
  String get ribbon;

  /// No description provided for @bright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get bright;

  /// No description provided for @turnNumber.
  ///
  /// In en, this message translates to:
  /// **'T{turn}'**
  String turnNumber(Object turn);

  /// No description provided for @playerNumber.
  ///
  /// In en, this message translates to:
  /// **'P{player}'**
  String playerNumber(Object player);

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @logViewer.
  ///
  /// In en, this message translates to:
  /// **'Log Viewer'**
  String get logViewer;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get logLevel;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @gameLog.
  ///
  /// In en, this message translates to:
  /// **'Game Log'**
  String get gameLog;

  /// No description provided for @systemLog.
  ///
  /// In en, this message translates to:
  /// **'System Log'**
  String get systemLog;

  /// No description provided for @animationLog.
  ///
  /// In en, this message translates to:
  /// **'Animation Log'**
  String get animationLog;

  /// No description provided for @soundLog.
  ///
  /// In en, this message translates to:
  /// **'Sound Log'**
  String get soundLog;

  /// No description provided for @networkLog.
  ///
  /// In en, this message translates to:
  /// **'Network Log'**
  String get networkLog;

  /// No description provided for @performanceLog.
  ///
  /// In en, this message translates to:
  /// **'Performance Log'**
  String get performanceLog;

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @filterByLevel.
  ///
  /// In en, this message translates to:
  /// **'Filter by Level'**
  String get filterByLevel;

  /// No description provided for @filterByPlayer.
  ///
  /// In en, this message translates to:
  /// **'Filter by Player'**
  String get filterByPlayer;

  /// No description provided for @filterByPhase.
  ///
  /// In en, this message translates to:
  /// **'Filter by Phase'**
  String get filterByPhase;

  /// No description provided for @noLogsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No logs available'**
  String get noLogsAvailable;

  /// No description provided for @logExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Log export failed'**
  String get logExportFailed;

  /// No description provided for @logExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Log export successful'**
  String get logExportSuccess;

  /// No description provided for @logClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all logs?'**
  String get logClearConfirm;

  /// No description provided for @logClearSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logClearSuccess;

  /// No description provided for @logClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear logs'**
  String get logClearFailed;

  /// No description provided for @dan.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get dan;

  /// No description provided for @goBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Go Bonus'**
  String get goBonusLabel;

  /// No description provided for @cardCountUnit.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cardCountUnit;

  /// No description provided for @ppeok.
  ///
  /// In en, this message translates to:
  /// **'Clash'**
  String get ppeok;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ko': return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
