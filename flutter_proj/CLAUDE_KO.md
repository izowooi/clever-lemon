# CLAUDE_KO.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소에서 작업할 때 참고할 한국어 가이드입니다.

## 프로젝트 개요

Poetry Writer는 Flutter 기반의 AI 시 창작 도우미 앱입니다. 사용자가 단어를 선택하면 AI가 시 템플릿을 생성해주는 앱으로, 구글, 애플, 게스트 로그인을 지원하며 현재 기본 인증 테스트 기능을 개발 중입니다.

## 개발 명령어

### 핵심 Flutter 명령어
- **의존성 설치**: `flutter pub get`
- **앱 실행**: `flutter run`
- **릴리즈 빌드**: `flutter build apk` (안드로이드) 또는 `flutter build ios` (iOS)
- **프로젝트 정리**: `flutter clean`
- **환경 확인**: `flutter doctor`

### 테스트 및 품질 관리
- **테스트 실행**: `flutter test`
- **코드 분석**: `flutter analyze`
- **코드 포맷**: `dart format .`

### Firebase 설정
앱은 Firebase를 원격 설정과 분석에 사용합니다. Firebase 설정 파일 위치:
- 안드로이드: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## 아키텍처

### 핵심 원칙
- **SOLID 원칙**과 Clean Architecture 적용
- 서비스를 위한 **인터페이스 기반 설계**와 어댑터 패턴
- **Riverpod**를 사용한 Provider 패턴 상태 관리
- 개발과 테스트를 위한 **Mock 구현체**

### 프로젝트 구조
```
lib/
├── models/                 # 도메인 모델 (Word, Poetry, PoetryTemplate, UserInfo)
├── services/
│   ├── interfaces/        # 모든 서비스의 추상 인터페이스
│   └── implementations/   # 구체 구현체 (Mock 및 실제 구현)
├── providers/             # Riverpod 상태 관리
├── screens/               # UI 화면 (개발용 DevTestScreen 포함)
└── widgets/               # 재사용 가능한 UI 컴포넌트
```

### 서비스 레이어 아키텍처
모든 서비스는 인터페이스 우선 설계를 따릅니다:
- **AuthAdapter**: 구글, 애플, 게스트 인증과 `AuthResult` 응답 패턴
- **RemoteConfigAdapter**: Firebase 원격 설정 관리
- **MessagingAdapter**: Firebase 메시징 (플레이스홀더)
- **ApiService**: 백엔드 API 통신
- **StorageService**: 로컬 데이터 지속성
- **PoetryService** & **WordService**: 핵심 비즈니스 로직

### 상태 관리
- **flutter_riverpod**를 Provider 패턴과 함께 사용
- 서비스는 프로바이더를 통해 싱글톤으로 제공
- 복잡한 상태는 StateNotifier 패턴으로 관리

### 개발 테스트
`DevTestScreen` (`lib/screens/dev_test_screen.dart`)은 테스트를 위한 탭 인터페이스를 제공합니다:
- **Auth 탭**: 구글, 애플, 게스트 인증 테스트
- **Remote Config 탭**: Firebase 원격 설정 테스트
- **Messaging 탭**: Firebase 메시징 플레이스홀더
- **Supabase 탭**: Supabase 연동 테스트

## 주요 의존성

### 핵심 프레임워크
- `flutter_riverpod: ^2.6.1` - 상태 관리
- `supabase_flutter: ^2.10.0` - 백엔드 서비스

### Firebase 서비스
- `firebase_core: ^4.0.0`
- `firebase_remote_config: ^6.0.0`
- `firebase_analytics: ^12.0.0`
- `firebase_messaging: ^16.0.0`

### 저장소 및 데이터
- `shared_preferences: ^2.5.3` - 로컬 설정
- `drift: ^2.28.1` - 로컬 데이터베이스 (계획됨)

### 유틸리티
- `http: ^1.5.0` - HTTP 클라이언트
- `package_info_plus: ^8.3.1` - 앱 정보
- `permission_handler: ^12.0.1` - 권한 관리

## 개발 참고사항

### 인증 테스트
DevTestScreen을 사용하여 인증 플로우를 테스트하세요:
1. Auth 탭으로 이동
2. 프로바이더 선택 (구글/애플/게스트)
3. 먼저 어댑터를 초기화
4. 로그인/로그아웃 기능 테스트
5. 통합 로그 뷰어에서 로그 확인

### Mock 서비스
모든 서비스는 개발용 Mock 구현체를 가지고 있습니다:
- `lib/services/implementations/mock_*.dart`에 위치
- 실제 구현체와 동일한 인터페이스를 따름
- 테스트를 위한 현실적인 지연과 응답 포함

### 패키지명
현재 안드로이드 패키지: 최신 패키지명 설정은 `android/app/build.gradle.kts`를 확인하세요.

### 코딩 스타일
- `ColorScheme.fromSeed`를 사용한 Material 3 테마
- UI 텍스트의 한국어 지원
- 12px 테두리 반경을 가진 일관된 카드 기반 UI
- 8px 테두리 반경을 가진 Elevated 버튼
- 문자열 연결은 문자열 보간 대신 `+` 연산자 사용

## 개발 팁

### Firebase 설정
- 원격 설정을 테스트할 때는 DevTestScreen의 Remote Config 탭 사용
- Firebase 콘솔에서 설정 값을 변경한 후 앱에서 fetch & activate 테스트

### 인증 어댑터 구현
새로운 인증 프로바이더를 추가할 때:
1. `AuthAdapter` 인터페이스를 구현
2. `AuthResult`를 사용하여 성공/실패 결과 반환
3. `DevTestScreen`에 새 탭 추가하여 테스트

### UI 개발
- 한국어 텍스트 사용 (개발자 화면에서 "초기화", "로그인", "로그아웃" 등)
- Material 3 디자인 가이드라인 준수
- 일관된 패딩과 마진 사용 (주로 16px, 12px, 8px)