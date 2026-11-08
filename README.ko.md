# Demo Booth Quiz

[English](README.md) | [한국어](README.ko.md)

한국어와 영어를 지원하는 Flutter 웹 퀴즈입니다. 기본 빌드는 이 데모를 위해 새로 만든 산술 문제 17개를 사용하며 Firebase나 Analytics에 연결하지 않습니다. 한 라운드에 네 문제를 출제하고, 언어를 바꿔도 답안 ID를 유지하며, 터치 화면에 맞는 레이아웃을 지원합니다. 실제 경품 수령 권한을 표시하지는 않습니다.

## 로컬 실행

Dart 3.13.7 또는 호환 버전이 포함된 Flutter와 캐시에 있거나 설치할 수 있는 의존성이 필요합니다.

```sh
flutter pub get
flutter run -d chrome
```

렌더러 리소스를 로컬에 포함한 정적 빌드:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8767 --bind 127.0.0.1 --directory build/web
```

http://127.0.0.1:8767 에 접속하세요. 의존성이 캐시에 없으면 설치할 때 인터넷 연결이 필요합니다. 정적 샘플 빌드에는 문제 데이터, 한국어 글꼴과 웹 렌더러가 포함됩니다. 서비스 워커를 통해 설치해 오프라인으로 사용하는 PWA는 아니며, 정적 페이지를 열 때도 로컬 서버가 필요합니다.

## 공개 정적 시연

Flutter와 Python 3으로 로그인과 영구 저장이 없는 시연을 빌드합니다:

```sh
flutter pub get
sh tools/build_public_demo.sh
```

별도 진입점인 `lib/demo.dart`는 독립적으로 새로 만든 산수 문제만 사용합니다. Firebase, Analytics, 문제 캐시나 언어 설정의 영구 저장을 초기화하지 않습니다. 관리자·로그인·보고서 경로는 사용할 수 없습니다. 이름이나 참가자 식별정보를 수집하지 않으며, 답변과 언어 선택은 새로고침하거나 페이지를 닫으면 초기화됩니다. 실제 경품은 제공하지 않습니다.

빌드는 `/flutter-korea-booth/` 기본 경로, 로컬 글꼴·렌더러와 라이선스, 정적 404 대체 페이지를 포함합니다. 생성된 `build/web` 내용을 `gh-pages` 브랜치로 배포해 GitHub Pages에서 제공합니다. 사용자 도메인, 백엔드, 비밀정보, CI 워크플로 파일이나 유료 서비스가 필요하지 않습니다. 배포할 때 `assets/NOTICES`와 `licenses` 폴더를 유지하세요. 호스팅 제공자의 HTTP 로그와 일반적인 브라우저 파일 캐시는 앱의 결과 저장과 별개입니다.

## 이 사본의 범위

- 원본 행사 문항과 해당 문항에 종속된 테스트 검증 항목을 제거했습니다. 새 문제 데이터는 이 데모를 위해 별도로 작성했습니다.
- 행사 이미지, 로고, 참가자 기록, 내보낸 파일, 로그, 생성된 빌드, 운영 문서, 프로덕션 설정과 릴리스 도구는 제외했습니다.
- 제공하는 빌드 대상은 웹입니다. Android/iOS/macOS 프로젝트 기본 구조, 서명 파일과 네이티브 브랜딩은 의도적으로 제외했습니다. 네이티브 저장소 코드는 예제로 남겨 두었지만 네이티브 빌드는 준비하거나 테스트하지 않았습니다.
- 앱 진입점에는 참가자 플레이 기록, 동기화, 분석이나 운영자 보고 기능이 연결되어 있지 않습니다. 재사용할 수 있는 관련 모듈과 단위 테스트는 참고용으로 남겨 두었습니다. 다시 활성화하려면 개인정보 처리·보관 정책과 최소 권한을 명확히 설계해야 합니다. 관리자 계정에 로그인한 상태를 공유하는 키오스크를 다시 구성하지 마세요.
- 공개 시연은 원본 운영 앱과 분리됩니다. 원본의 프로덕션 Firebase 규칙·Auth·데이터·호스팅은 변경하지 않습니다.

## 선택 사항: Firebase 문제 관리

기본 샘플 모드에는 Firebase 계정이나 SDK 다운로드가 필요하지 않습니다. 선택 사항인 웹 Firebase 모드는 Google 공식 gstatic CDN에서 SDK 13.1.0을 내려받으므로 로컬 에뮬레이터를 사용할 때도 인터넷 연결이 필요합니다. 로컬 에뮬레이터 실행 방법:

```sh
firebase emulators:start --project demo-quiz --only firestore,auth
# In another terminal, install tool dependencies first:
npm --prefix tools ci
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node tools/firebase_admin.mjs bootstrap-emulator demo-quiz
flutter run -d chrome --dart-define-from-file=config/emulator.json
```

에뮬레이터 전용 운영자 계정은 host@example.test / LocalDemoOnly123! 입니다. 이 데모 비밀번호를 실제 서비스에서 사용하지 마세요. 도우미는 실제 프로젝트 ID나 루프백이 아닌 엔드포인트를 거부합니다. Firebase CLI와 Java 21 이상은 별도로 준비해야 합니다.

자신의 프로젝트를 연결하려면 config/firebase.example.json을 Git 추적에서 제외된 config/firebase.json으로 복사한 뒤 자신의 공개 웹 설정을 입력하세요. 프로덕션 프로젝트는 미리 지정되어 있지 않습니다. 공개 정적 시연 빌드는 Firebase 호스팅과 분리됩니다. Firebase Auth, 서버에서 강제하는 quizAdmin 클레임과 Firestore 규칙은 직접 통제하는 환경에서 구성하세요. 클라이언트 define 값에 서비스 계정 키, 리프레시 토큰이나 운영자 비밀번호를 넣지 마세요. 웹 클라이언트 API 키는 공개 설정이며 관리자 인증정보가 아닙니다.

관리자 경로에 들어갈 때마다 기존 인증 상태를 지운 뒤 로그인 화면을 표시합니다. 나갈 때도 인증 상태를 지운 다음 퀴즈로 돌아가며, 정리에 실패하면 재시도가 성공할 때까지 이동을 막습니다. 웹 Auth는 인증 상태를 메모리에만 유지하며 Firestore의 영구 캐시는 비활성화되어 있습니다. 잠금이 풀린 관리자 화면은 운영자가 직접 보호해야 합니다. 로컬 인증 상태를 지워도 서버에서 토큰이 폐기되는 것은 아닙니다.

## 검증

```sh
flutter analyze
flutter test
npm --prefix tools run test:session
npm --prefix tools run test:emulators
```

규칙 테스트는 demo-quiz-tests와 격리된 루프백 포트 8085/9095를 사용합니다. 테스트 설정은 실제 프로젝트와 미리보기용 포트를 거부합니다. 테스트를 실제 Firebase에 연결하지 마세요.

선택 사항인 Firebase 브라우저/CDN 연동은 테스트하지 않았습니다. 에뮬레이터 테스트 통과만으로 이 연동을 검증한 것은 아닙니다.

검증 기록과 한계는 docs/VALIDATION.md를, 보안 경계는 SECURITY.md를 확인하세요. 이 사본은 검토를 거친 데모 소스이며 프로덕션 보안 인증을 받은 것은 아닙니다.

## 라이선스

이 사본의 앱 자체 코드는 MIT 라이선스로 제공합니다. LICENSE와 LICENSE_DECISION.md를 확인하세요. 저작권 표기는 Copyright (c) 2026 curogom입니다. 제3자 코드, 의존성과 글꼴은 각자의 라이선스와 저작권 고지를 유지합니다. THIRD_PARTY_NOTICES.md를 확인하세요. 제외한 원본 행사 문항, 이미지와 브랜딩에는 이 MIT 라이선스를 적용하지 않습니다. 라이선스 선택만으로 이 사본이 공개되거나 배포되지는 않습니다.
