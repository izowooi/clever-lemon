# Poetry Writer

Poetry Writer는 AI 기술을 활용한 시 창작 도우미 모바일 앱입니다.

## 기능

### 🎨 시 창작 기능
- **순차적 창작**: 단계별로 단어를 선택하여 자연스러운 창작 과정
- **일괄 창작**: 한 번에 여러 단어를 선택하여 빠른 창작
- **AI 시 생성**: 선택한 키워드를 바탕으로 AI가 4가지 시 템플릿 제공
- **편집 기능**: 생성된 시를 자유롭게 편집하여 완성

### 📱 플랫폼 지원
- Android
- iOS

## 프로젝트 구조

```
lib/
├── models/          # 도메인 모델 (Word, Poetry, PoetryTemplate)
├── services/        # 비즈니스 로직
│   ├── interfaces/  # 추상 인터페이스
│   └── implementations/ # Mock 구현체
├── providers/       # 상태 관리 (Provider 패턴)
├── screens/         # 화면 위젯
└── widgets/         # 재사용 가능한 위젯
```

## 기술 스택

- **Flutter**: 크로스플랫폼 모바일 앱 개발
- **Provider**: 상태 관리
- **SharedPreferences**: 로컬 데이터 저장
- **SOLID 원칙**: 확장 가능하고 유지보수 용이한 아키텍처

## 시작하기

### 전제 조건
- Flutter SDK (3.9.0 이상)
- Android Studio 또는 VS Code
- iOS 개발의 경우 Xcode (macOS에서만)

### 설치 및 실행

1. 저장소 클론
```bash
git clone <repository-url>
cd flutter_proj
```

2. 의존성 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
flutter run
```

## 개발자 명령어

### 버전 확인

- Flutter 버전과 Flutter에 번들된 Dart 버전 확인
```bash
flutter --version
```

- 별도로 설치한 Dart SDK 버전 확인(선택)
```bash
dart --version
```

- 환경 진단(선택, 상세 출력)
```bash
flutter doctor -v
```

## 향후 계획

- [ ] 실제 AI API 연동
- [ ] 작품 목록 기능 구현
- [ ] 설정 화면 구현  
- [ ] 클라우드 동기화
- [ ] 작품 공유 기능
