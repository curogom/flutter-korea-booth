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
/// import 'generated/app_localizations.dart';
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
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo Booth Quiz'**
  String get appTitle;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'DEMO CHALLENGE'**
  String get challenge;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'New arithmetic questions, not event questions.\nNo prizes. Answers stay only in this page.'**
  String get invite;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start the demo quiz'**
  String get startQuiz;

  /// No description provided for @winRule.
  ///
  /// In en, this message translates to:
  /// **'3 out of 4 correct completes the demo!'**
  String get winRule;

  /// No description provided for @loadingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Loading your questions…'**
  String get loadingQuestions;

  /// No description provided for @questionsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The quiz is being prepared. Please ask a booth host.'**
  String get questionsUnavailable;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions. Please check the connection.'**
  String get loadError;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get home;

  /// No description provided for @confirmAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get confirmAnswer;

  /// No description provided for @selectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Which answer looks right?'**
  String get selectPrompt;

  /// No description provided for @selectHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick an answer, then check it.'**
  String get selectHelp;

  /// No description provided for @changeHelp.
  ///
  /// In en, this message translates to:
  /// **'You can change your answer before checking.'**
  String get changeHelp;

  /// No description provided for @correctFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct! One step forward.'**
  String get correctFeedback;

  /// No description provided for @incorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'That’s okay — you learned something!'**
  String get incorrectFeedback;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Moving to the next question'**
  String get nextQuestion;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Moving to your results'**
  String get showResults;

  /// No description provided for @dashWelcome.
  ///
  /// In en, this message translates to:
  /// **'Ready for a little number puzzle?'**
  String get dashWelcome;

  /// No description provided for @dashSelected.
  ///
  /// In en, this message translates to:
  /// **'Ready? Let’s check your answer.'**
  String get dashSelected;

  /// No description provided for @dashCorrect.
  ///
  /// In en, this message translates to:
  /// **'Nice! Let’s take the next step together.'**
  String get dashCorrect;

  /// No description provided for @dashIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Good effort. Let’s keep going!'**
  String get dashIncorrect;

  /// No description provided for @correctCount.
  ///
  /// In en, this message translates to:
  /// **'correct'**
  String get correctCount;

  /// No description provided for @threeToWin.
  ///
  /// In en, this message translates to:
  /// **'Three to complete!'**
  String get threeToWin;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'You did it!'**
  String get successTitle;

  /// No description provided for @successSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Demo challenge complete!'**
  String get successSubtitle;

  /// No description provided for @tryTitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for playing.'**
  String get tryTitle;

  /// No description provided for @trySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep moving forward!'**
  String get trySubtitle;

  /// No description provided for @successMessage.
  ///
  /// In en, this message translates to:
  /// **'One step forward, together!'**
  String get successMessage;

  /// No description provided for @tryMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing what you learned today.'**
  String get tryMessage;

  /// No description provided for @nextPlayer.
  ///
  /// In en, this message translates to:
  /// **'Next player'**
  String get nextPlayer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Manage questions'**
  String get admin;

  /// No description provided for @sampleMode.
  ///
  /// In en, this message translates to:
  /// **'Sample mode'**
  String get sampleMode;

  /// No description provided for @adminSignIn.
  ///
  /// In en, this message translates to:
  /// **'Host sign-in'**
  String get adminSignIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'This account does not have question editor access.'**
  String get accessDenied;

  /// No description provided for @refreshAccess.
  ///
  /// In en, this message translates to:
  /// **'Refresh access'**
  String get refreshAccess;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please check your account details.'**
  String get authError;

  /// No description provided for @firebaseRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect a Firebase project to add and edit questions.'**
  String get firebaseRequired;

  /// No description provided for @addQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get addQuestion;

  /// No description provided for @editQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit question'**
  String get editQuestion;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @publishQuestion.
  ///
  /// In en, this message translates to:
  /// **'Publish for players'**
  String get publishQuestion;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Display order'**
  String get order;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get correctAnswer;

  /// No description provided for @questionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionPrompt;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidOrder.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of zero or more.'**
  String get invalidOrder;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please check your access and connection.'**
  String get saveError;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Changes apply to the next player.'**
  String get saved;

  /// No description provided for @questionListError.
  ///
  /// In en, this message translates to:
  /// **'Could not load questions. Please check data format and permissions.'**
  String get questionListError;

  /// No description provided for @noQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions have been added yet.'**
  String get noQuestions;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get archive;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Complete both Korean and English text and choices. The correct choice is shared across both languages.'**
  String get adminNote;

  /// No description provided for @leaveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Return to quiz'**
  String get leaveAdmin;

  /// No description provided for @setupError.
  ///
  /// In en, this message translates to:
  /// **'Please check the Firebase configuration.'**
  String get setupError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {number} / {total}'**
  String questionNumber(int number, int total);

  /// No description provided for @resultScore.
  ///
  /// In en, this message translates to:
  /// **'{score} out of 4 correct.'**
  String resultScore(int score);

  /// No description provided for @selectedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Selected: {answer}'**
  String selectedAnswer(String answer);

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Choice {letter}'**
  String optionLabel(String letter);

  /// No description provided for @retryQuestions.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryQuestions;

  /// No description provided for @savedQuestionsNotice.
  ///
  /// In en, this message translates to:
  /// **'Using questions saved on this device.'**
  String get savedQuestionsNotice;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Participation records'**
  String get operations;

  /// No description provided for @operationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows this device’s records and the latest 500 server records.'**
  String get operationsHelp;

  /// No description provided for @shownRuns.
  ///
  /// In en, this message translates to:
  /// **'Displayed runs'**
  String get shownRuns;

  /// No description provided for @completedRuns.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedRuns;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSync;

  /// No description provided for @recordsSyncError.
  ///
  /// In en, this message translates to:
  /// **'Device records are preserved. Check host sign-in, connectivity and records needing review, then sync again.'**
  String get recordsSyncError;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @noRunRecords.
  ///
  /// In en, this message translates to:
  /// **'No participation records yet.'**
  String get noRunRecords;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @interruptedRun.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get interruptedRun;

  /// No description provided for @swagPickup.
  ///
  /// In en, this message translates to:
  /// **'This is a demo. No prizes or rewards are issued.'**
  String get swagPickup;

  /// No description provided for @passedRuns.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passedRuns;

  /// No description provided for @searchRun.
  ///
  /// In en, this message translates to:
  /// **'Search run ID'**
  String get searchRun;

  /// No description provided for @questionAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Question accuracy'**
  String get questionAccuracy;

  /// No description provided for @accuracyScope.
  ///
  /// In en, this message translates to:
  /// **'Combines device records with the latest 500 server runs. Counts confirmed answers, including answers from interrupted runs.'**
  String get accuracyScope;

  /// No description provided for @responseCount.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get responseCount;

  /// No description provided for @correctResponses.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctResponses;

  /// No description provided for @incorrectResponses.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrectResponses;

  /// No description provided for @accuracyRate.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyRate;

  /// No description provided for @overallAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Overall accuracy'**
  String get overallAccuracy;

  /// No description provided for @runLanguage.
  ///
  /// In en, this message translates to:
  /// **'Last language of each run'**
  String get runLanguage;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLanguages;

  /// No description provided for @productionData.
  ///
  /// In en, this message translates to:
  /// **'Production data'**
  String get productionData;

  /// No description provided for @testData.
  ///
  /// In en, this message translates to:
  /// **'Test data'**
  String get testData;

  /// No description provided for @accuracyPartialData.
  ///
  /// In en, this message translates to:
  /// **'Some records may be out of date. Figures use displayed data. Reload after the connection recovers.'**
  String get accuracyPartialData;

  /// No description provided for @noAccuracyData.
  ///
  /// In en, this message translates to:
  /// **'No questions or responses to report yet.'**
  String get noAccuracyData;

  /// No description provided for @alreadyOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'The quiz is open in another tab'**
  String get alreadyOpenTitle;

  /// No description provided for @alreadyOpenHelp.
  ///
  /// In en, this message translates to:
  /// **'Continue playing in the existing tab. If you have closed that tab, you can try again here.'**
  String get alreadyOpenHelp;

  /// No description provided for @startUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'The quiz could not start safely'**
  String get startUnavailableTitle;

  /// No description provided for @startUnavailableHelp.
  ///
  /// In en, this message translates to:
  /// **'Reload the page or use the latest Chrome. Ask a booth host if the problem continues.'**
  String get startUnavailableHelp;

  /// No description provided for @recordsNeedReview.
  ///
  /// In en, this message translates to:
  /// **'Sync needs review'**
  String get recordsNeedReview;

  /// No description provided for @demoRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Admin, sign-in and reporting pages are not available in this public demo.'**
  String get demoRouteUnavailable;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
