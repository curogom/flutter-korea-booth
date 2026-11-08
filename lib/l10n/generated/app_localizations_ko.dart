// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '데모 부스 퀴즈';

  @override
  String get challenge => 'DEMO CHALLENGE';

  @override
  String get invite => '행사 문제 대신 새로 만든 산수 문제입니다.\n경품은 없으며, 답변은 이 페이지에서만 유지됩니다.';

  @override
  String get startQuiz => '데모 퀴즈 시작';

  @override
  String get winRule => '4문제 중 3문제 정답으로 데모 완료!';

  @override
  String get loadingQuestions => '문제를 불러오는 중이에요.';

  @override
  String get questionsUnavailable => '문제를 준비하고 있어요. 스태프에게 문의해주세요.';

  @override
  String get loadError => '문제를 불러오지 못했어요. 연결 상태를 확인해주세요.';

  @override
  String get home => '처음으로';

  @override
  String get confirmAnswer => '정답 확인';

  @override
  String get selectPrompt => '어떤 답이 맞을까요?';

  @override
  String get selectHelp => '답을 고른 뒤 정답 확인을 눌러주세요.';

  @override
  String get changeHelp => '확인 전에는 답을 바꿀 수 있어요.';

  @override
  String get correctFeedback => '정답! 한 걸음 더 앞으로.';

  @override
  String get incorrectFeedback => '괜찮아요, 하나 알아갔어요!';

  @override
  String get nextQuestion => '다음 문제로 이동';

  @override
  String get showResults => '결과 화면으로 이동';

  @override
  String get dashWelcome => '가벼운 숫자 퀴즈를 시작해볼까요?';

  @override
  String get dashSelected => '준비됐다면 정답을 확인해보세요.';

  @override
  String get dashCorrect => '좋아요! 다음 한 걸음도 함께해요.';

  @override
  String get dashIncorrect => '좋은 도전이에요. 계속 가볼까요?';

  @override
  String get correctCount => '개 정답';

  @override
  String get threeToWin => '3문제 정답으로 완료!';

  @override
  String get selected => '선택';

  @override
  String get successTitle => '해냈어요!';

  @override
  String get successSubtitle => '데모 미션 성공!';

  @override
  String get tryTitle => '멋진 도전이었어요.';

  @override
  String get trySubtitle => '다음 한 걸음도 함께!';

  @override
  String get successMessage => '함께, 한 걸음 더 앞으로!';

  @override
  String get tryMessage => '오늘 배운 내용을 다시 연습해보세요.';

  @override
  String get nextPlayer => '다음 참가자';

  @override
  String get language => '언어';

  @override
  String get admin => '문제 관리';

  @override
  String get sampleMode => '샘플 모드';

  @override
  String get adminSignIn => '운영자 로그인';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get accessDenied => '문제 편집 권한이 없는 계정입니다.';

  @override
  String get refreshAccess => '권한 새로고침';

  @override
  String get authError => '로그인하지 못했습니다. 계정 정보를 확인해주세요.';

  @override
  String get firebaseRequired => 'Firebase 프로젝트를 연결하면 문제를 추가·수정할 수 있습니다.';

  @override
  String get addQuestion => '문제 추가';

  @override
  String get editQuestion => '문제 수정';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get published => '게시';

  @override
  String get draft => '비공개';

  @override
  String get publishQuestion => '참가자에게 게시';

  @override
  String get order => '표시 순서';

  @override
  String get correctAnswer => '정답';

  @override
  String get questionPrompt => '문제';

  @override
  String get explanation => '해설';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get requiredField => '필수 항목입니다.';

  @override
  String get invalidOrder => '0 이상의 정수를 입력해주세요.';

  @override
  String get saveError => '저장하지 못했습니다. 권한과 연결 상태를 확인해주세요.';

  @override
  String get saved => '저장했습니다. 다음 참가자부터 반영됩니다.';

  @override
  String get questionListError => '문제 목록을 불러오지 못했습니다. 데이터 형식과 권한을 확인해주세요.';

  @override
  String get noQuestions => '아직 등록된 문제가 없습니다.';

  @override
  String get archive => '비공개로 전환';

  @override
  String get publish => '게시하기';

  @override
  String get adminNote =>
      '한국어·영어 문제와 선택지를 모두 입력해주세요. 정답은 두 언어에서 같은 선택지를 가리킵니다.';

  @override
  String get leaveAdmin => '퀴즈로 돌아가기';

  @override
  String get setupError => 'Firebase 설정을 확인해주세요.';

  @override
  String get retry => '다시 시도';

  @override
  String questionNumber(int number, int total) {
    return '문제 $number / $total';
  }

  @override
  String resultScore(int score) {
    return '4문제 중 $score개 정답.';
  }

  @override
  String selectedAnswer(String answer) {
    return '선택한 답: $answer';
  }

  @override
  String optionLabel(String letter) {
    return '선택지 $letter';
  }

  @override
  String get retryQuestions => '다시 불러오기';

  @override
  String get savedQuestionsNotice => '이 기기에 저장된 문제로 진행합니다.';

  @override
  String get operations => '참여 기록';

  @override
  String get operationsHelp => '현재 기기 기록과 최근 서버 기록 500개를 함께 표시합니다.';

  @override
  String get shownRuns => '표시된 참여';

  @override
  String get completedRuns => '완료';

  @override
  String get pendingSync => '전송 대기';

  @override
  String get recordsSyncError =>
      '기기 기록은 보존됩니다. 운영자 로그인·연결 상태와 확인이 필요한 기록을 점검한 뒤 다시 동기화해주세요.';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get noRunRecords => '아직 참여 기록이 없습니다.';

  @override
  String get inProgress => '진행 중';

  @override
  String get interruptedRun => '중단';

  @override
  String get swagPickup => '데모 화면입니다. 경품이나 보상은 제공하지 않습니다.';

  @override
  String get passedRuns => '성공';

  @override
  String get searchRun => '회차 ID 검색';

  @override
  String get questionAccuracy => '문항별 정답률';

  @override
  String get accuracyScope =>
      '현재 기기 기록과 최근 서버 500회차를 합쳐, 확정한 답변만 집계합니다. 중단한 회차의 확정 응답도 포함합니다.';

  @override
  String get responseCount => '응답 수';

  @override
  String get correctResponses => '정답 수';

  @override
  String get incorrectResponses => '오답 수';

  @override
  String get accuracyRate => '정답률';

  @override
  String get overallAccuracy => '전체 정답률';

  @override
  String get runLanguage => '회차의 마지막 언어';

  @override
  String get allLanguages => '전체';

  @override
  String get productionData => '운영 데이터';

  @override
  String get testData => '테스트 데이터';

  @override
  String get accuracyPartialData =>
      '일부 기록이 최신 상태가 아닐 수 있습니다. 표시된 데이터로 집계하며 연결 복구 후 다시 불러올 수 있습니다.';

  @override
  String get noAccuracyData => '집계할 문항이나 응답이 아직 없습니다.';

  @override
  String get alreadyOpenTitle => '다른 탭에서 퀴즈가 열려 있어요';

  @override
  String get alreadyOpenHelp =>
      '진행 중인 퀴즈는 기존 탭에서 계속해주세요. 기존 탭을 닫았다면 다시 시도할 수 있어요.';

  @override
  String get startUnavailableTitle => '퀴즈를 안전하게 시작하지 못했어요';

  @override
  String get startUnavailableHelp =>
      '페이지를 새로고침하거나 최신 Chrome으로 접속해주세요. 계속 문제가 생기면 스태프에게 알려주세요.';

  @override
  String get recordsNeedReview => '동기화 확인 필요';

  @override
  String get demoRouteUnavailable => '공개 시연에서는 관리자, 로그인, 보고서 페이지를 제공하지 않습니다.';
}
