# 🌸 클레버 레몬 - AI 시 창작 API 서버 🍋

> 한국어 시 창작의 새로운 패러다임! AI와 함께 감성적인 시를 만들어보세요.

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white)](https://openai.com/)

## 🚀 프로젝트 소개

본 프로젝트는 AI의 힘을 빌려 아름다운 한국어 시를 창작하는 서비스입니다. Flutter 모바일 앱의 백엔드로 설계되었으며, 사용자는 자신만의 감성과 키워드를 바탕으로 개성 있는 시를 생성할 수 있습니다.

### ✨ 주요 기능

- 🎭 **다양한 시 스타일**: 윤동주, 김소월 등 유명 시인의 스타일로 시 창작
- 🎨 **감정 기반 창작**: 낭만적, 우울한, 희망적 등 다양한 감정 표현
- 🔑 **키워드 활용**: 사용자가 입력한 키워드를 자연스럽게 녹인 시 생성
- 💎 **크레딧 시스템**: 공정한 사용을 위한 크레딧 기반 서비스
- 🔐 **보안 인증**: Supabase JWT 토큰을 통한 안전한 사용자 인증

## 🏗️ 시스템 아키텍처

```mermaid
graph TB
    subgraph "Client Layer"
        Flutter[📱 Flutter App]
    end
    
    subgraph "API Gateway"
        CloudRun[☁️ Google Cloud Run<br/>FastAPI Server]
    end
    
    subgraph "Authentication"
        Supabase[🔐 Supabase Auth<br/>JWT Verification]
    end
    
    subgraph "AI Services"
        GPT4o[🤖 GPT-4o<br/>Chat Completions]
        GPT5[🧠 GPT-5<br/>Responses API]
    end
    
    subgraph "Database"
        SupabaseDB[(🗄️ Supabase DB<br/>User Credits)]
    end
    
    Flutter --> CloudRun
    CloudRun --> Supabase
    CloudRun --> GPT4o
    CloudRun --> GPT5
    CloudRun --> SupabaseDB
    
    style Flutter fill:#e1f5fe
    style CloudRun fill:#f3e5f5
    style Supabase fill:#e8f5e8
    style GPT4o fill:#fff3e0
    style GPT5 fill:#fff3e0
    style SupabaseDB fill:#f1f8e9
```

## 🎯 API 엔드포인트

### 🏥 헬스체크
```http
GET /ping
```
서버 상태를 확인합니다.

### 🔑 인증 관련
```http
POST /auth/register        # 사용자 등록 (액세스 토큰)
```

### 🌸 시 생성 (핵심 기능!)
```http
POST /poems/generate
```

**요청 예시:**
```json
{
  "user_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "style": "낭만적인",
  "author_style": "윤동주",
  "keywords": ["달", "그리움", "희망"],
  "length": "8행"
}
```

**응답 예시:**
```json
{
  "success": true,
  "request": {
    "style": "낭만적인",
    "author_style": "윤동주",
    "keywords": ["달", "그리움", "희망"],
    "length": "8행"
  },
  "poems": [
    "밤하늘의 달빛\n\n그리운 마음 속에\n달빛이 스며들어\n희망의 씨앗을 심네\n...",
    "두 번째 시...",
    "세 번째 시...",
    "네 번째 시..."
  ],
  "generation_time": 25.3,
  "remaining_credits": 99
}
```

## 🔧 개발 환경 설정

### 📋 필수 요구사항
- 🐍 Python 3.12+
- 📦 uv 패키지 매니저
- 🔑 OpenAI API Key
- 🔐 Supabase 프로젝트 설정

### 🛠️ 로컬 개발 시작하기

1. **저장소 클론**
   ```bash
   git clone https://github.com/izowooi/clever-lemon.git
   cd clever-lemon
   ```

2. **종속성 설치**
   ```bash
   uv sync
   ```

3. **환경변수 설정**
   ```bash
   cp .env.example .env
   # .env 파일을 열어 실제 값들로 수정하세요
   ```

4. **개발 서버 실행**
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

5. **API 문서 확인**
   ```
   📖 Swagger UI: http://localhost:8000/docs
   📋 ReDoc: http://localhost:8000/redoc
   ```

## 🧪 테스트 방법

### 📡 HTTP 파일을 이용한 테스트
프로젝트에 포함된 `test_main.http` 파일을 사용하여 모든 엔드포인트를 테스트할 수 있습니다.

```bash
# VS Code REST Client 확장을 설치한 후
# test_main.http 파일을 열어 각 요청을 실행
```

### 🎭 시 생성 테스트 시나리오

```mermaid
sequenceDiagram
    participant Client as 📱 클라이언트
    participant API as 🚀 API 서버
    participant DB as 🗄️ Supabase DB
    participant AI as 🤖 OpenAI

    Client->>API: POST /poems/generate
    API->>DB: 크레딧 확인
    DB-->>API: 크레딧 정보
    API->>AI: 시 생성 요청
    AI-->>API: 생성된 시 4편
    API->>DB: 크레딧 1 차감
    API-->>Client: 시 + 남은 크레딧
```

## 🌐 배포 가이드

### 🚀 자동 배포 (추천)
```bash
# deploy.sh 스크립트 실행
./deploy.sh
```

### ⚙️ 수동 배포
```bash
# Google Cloud CLI 설정 후
gcloud run deploy clever-lemon \
    --source . \
    --region=asia-northeast1 \
    --platform=managed \
    --allow-unauthenticated
```

### 🔧 환경변수 설정
배포 시 다음 환경변수들이 필요합니다:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
OPENAI_API_KEY=sk-your-openai-api-key
OPENAI_MODEL=gpt-5-mini-2025-08-07  # 또는 gpt-4o-mini
```

## 🏛️ 프로젝트 구조

```
📦 clever-lemon/cloud_run_proj
├── 🐍 main.py                     # FastAPI 메인 애플리케이션
├── 🔐 verify_token.py             # JWT 토큰 검증 모듈
├── 🎨 poem_generator_modern.py    # AI 시 생성 엔진
├── 📋 pyproject.toml              # 프로젝트 의존성
├── 🐳 Dockerfile                  # 컨테이너 설정
├── 🚀 deploy.sh                   # 자동 배포 스크립트
├── 🧪 test_main.http              # API 테스트 파일
├── 📝 .env.example                # 환경변수 템플릿
└── 📚 docs/                       # 문서 디렉토리
```

## 🔍 기술 스택 상세

### 🎨 AI 시 생성 시스템
- **GPT-4o 모델**: 전통적인 Chat Completions API 활용
- **GPT-5 모델**: 최신 Responses API와 reasoning 기능 활용
- **이중 파싱 시스템**: JSON 파싱 실패 시 fallback 메커니즘

### 💳 크레딧 시스템
- **사전 검증**: 시 생성 전 크레딧 확인
- **트랜잭션 안전성**: 성공 시에만 크레딧 차감
- **실시간 업데이트**: 남은 크레딧 정보 실시간 제공

### 🔐 보안 시스템
- **JWT 검증**: Supabase 표준 JWT 토큰 검증
- **알고리즘 지원**: ES256, RS256, EdDSA
- **키 회전 대응**: JWKS 엔드포인트 활용

## 🌟 미래 계획

```mermaid
mindmap
  root((🌸 클레버 레몬))
    🎯 핵심 기능
      🎭 더 많은 시인 스타일
      🎨 이미지 기반 시 생성
      🎵 운율 분석 시스템
    🔧 기술 개선
      ⚡ 성능 최적화
      📊 실시간 분석
      🤖 AI 모델 업그레이드
    🌐 확장 기능
      🗣️ 음성 낭독
      📚 시집 생성
      👥 커뮤니티 기능
```

## 📄 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 확인하세요.

## 📞 문의하기

- 💼 프로젝트 이슈: [GitHub Issues](https://github.com/izowooi/clever-lemon/issues)

---

<div align="center">

**🌸 아름다운 시의 세계로 여러분을 초대합니다 🌸**

Made with 💖 by izowooi

</div>