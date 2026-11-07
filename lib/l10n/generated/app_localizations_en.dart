// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Demo Booth Quiz';

  @override
  String get challenge => 'DEMO CHALLENGE';

  @override
  String get invite =>
      'Try four original demo questions.\nThis demo does not award prizes.';

  @override
  String get startQuiz => 'Start the demo quiz';

  @override
  String get winRule => '3 out of 4 correct to win!';

  @override
  String get loadingQuestions => 'Loading your questions…';

  @override
  String get questionsUnavailable =>
      'The quiz is being prepared. Please ask a booth host.';

  @override
  String get loadError =>
      'Could not load questions. Please check the connection.';

  @override
  String get home => 'Back to start';

  @override
  String get confirmAnswer => 'Check answer';

  @override
  String get selectPrompt => 'Which answer looks right?';

  @override
  String get selectHelp => 'Pick an answer, then check it.';

  @override
  String get changeHelp => 'You can change your answer before checking.';

  @override
  String get correctFeedback => 'Correct! One step forward.';

  @override
  String get incorrectFeedback => 'That’s okay — you learned something!';

  @override
  String get nextQuestion => 'Moving to the next question';

  @override
  String get showResults => 'Moving to your results';

  @override
  String get dashWelcome => 'Ready for a little number puzzle?';

  @override
  String get dashSelected => 'Ready? Let’s check your answer.';

  @override
  String get dashCorrect => 'Nice! Let’s take the next step together.';

  @override
  String get dashIncorrect => 'Good effort. Let’s keep going!';

  @override
  String get correctCount => 'correct';

  @override
  String get threeToWin => 'Three to win!';

  @override
  String get selected => 'Selected';

  @override
  String get successTitle => 'You did it!';

  @override
  String get successSubtitle => 'Demo challenge complete!';

  @override
  String get tryTitle => 'Thanks for playing.';

  @override
  String get trySubtitle => 'Keep moving forward!';

  @override
  String get successMessage => 'One step forward, together!';

  @override
  String get tryMessage => 'Keep practicing what you learned today.';

  @override
  String get nextPlayer => 'Next player';

  @override
  String get language => 'Language';

  @override
  String get admin => 'Manage questions';

  @override
  String get sampleMode => 'Sample mode';

  @override
  String get adminSignIn => 'Host sign-in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get accessDenied =>
      'This account does not have question editor access.';

  @override
  String get refreshAccess => 'Refresh access';

  @override
  String get authError =>
      'Could not sign in. Please check your account details.';

  @override
  String get firebaseRequired =>
      'Connect a Firebase project to add and edit questions.';

  @override
  String get addQuestion => 'Add question';

  @override
  String get editQuestion => 'Edit question';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get published => 'Published';

  @override
  String get draft => 'Draft';

  @override
  String get publishQuestion => 'Publish for players';

  @override
  String get order => 'Display order';

  @override
  String get correctAnswer => 'Correct answer';

  @override
  String get questionPrompt => 'Question';

  @override
  String get explanation => 'Explanation';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get invalidOrder => 'Enter a whole number of zero or more.';

  @override
  String get saveError =>
      'Could not save. Please check your access and connection.';

  @override
  String get saved => 'Saved. Changes apply to the next player.';

  @override
  String get questionListError =>
      'Could not load questions. Please check data format and permissions.';

  @override
  String get noQuestions => 'No questions have been added yet.';

  @override
  String get archive => 'Unpublish';

  @override
  String get publish => 'Publish';

  @override
  String get adminNote =>
      'Complete both Korean and English text and choices. The correct choice is shared across both languages.';

  @override
  String get leaveAdmin => 'Return to quiz';

  @override
  String get setupError => 'Please check the Firebase configuration.';

  @override
  String get retry => 'Try again';

  @override
  String questionNumber(int number, int total) {
    return 'Question $number / $total';
  }

  @override
  String resultScore(int score) {
    return '$score out of 4 correct.';
  }

  @override
  String selectedAnswer(String answer) {
    return 'Selected: $answer';
  }

  @override
  String optionLabel(String letter) {
    return 'Choice $letter';
  }

  @override
  String get retryQuestions => 'Try again';

  @override
  String get savedQuestionsNotice => 'Using questions saved on this device.';

  @override
  String get operations => 'Participation records';

  @override
  String get operationsHelp =>
      'Shows this device’s records and the latest 500 server records.';

  @override
  String get shownRuns => 'Displayed runs';

  @override
  String get completedRuns => 'Completed';

  @override
  String get pendingSync => 'Pending sync';

  @override
  String get recordsSyncError =>
      'Device records are preserved. Check host sign-in, connectivity and records needing review, then sync again.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get noRunRecords => 'No participation records yet.';

  @override
  String get inProgress => 'In progress';

  @override
  String get interruptedRun => 'Interrupted';

  @override
  String get swagPickup => 'This is a demo. No prizes or rewards are issued.';

  @override
  String get passedRuns => 'Passed';

  @override
  String get searchRun => 'Search run ID';

  @override
  String get questionAccuracy => 'Question accuracy';

  @override
  String get accuracyScope =>
      'Combines device records with the latest 500 server runs. Counts confirmed answers, including answers from interrupted runs.';

  @override
  String get responseCount => 'Responses';

  @override
  String get correctResponses => 'Correct';

  @override
  String get incorrectResponses => 'Incorrect';

  @override
  String get accuracyRate => 'Accuracy';

  @override
  String get overallAccuracy => 'Overall accuracy';

  @override
  String get runLanguage => 'Last language of each run';

  @override
  String get allLanguages => 'All';

  @override
  String get productionData => 'Production data';

  @override
  String get testData => 'Test data';

  @override
  String get accuracyPartialData =>
      'Some records may be out of date. Figures use displayed data. Reload after the connection recovers.';

  @override
  String get noAccuracyData => 'No questions or responses to report yet.';

  @override
  String get alreadyOpenTitle => 'The quiz is open in another tab';

  @override
  String get alreadyOpenHelp =>
      'Continue playing in the existing tab. If you have closed that tab, you can try again here.';

  @override
  String get startUnavailableTitle => 'The quiz could not start safely';

  @override
  String get startUnavailableHelp =>
      'Reload the page or use the latest Chrome. Ask a booth host if the problem continues.';

  @override
  String get recordsNeedReview => 'Sync needs review';
}
