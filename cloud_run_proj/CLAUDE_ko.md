# CLAUDE_ko.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 코드 작업을 할 때 참고할 가이드를 제공합니다.

## 프로젝트 개요

Google Cloud Run 배포를 위해 설계된 FastAPI 기반의 시 생성 API 서비스입니다. Supabase Google 인증을 사용하는 Flutter 모바일 앱의 백엔드 역할을 하며, 사용자 재화 관리, 설정 관리, 결제 처리, AI 기반 시 생성 기능을 포함합니다.

## 아키텍처

- **메인 애플리케이션**: `main.py` - REST 엔드포인트가 있는 FastAPI 애플리케이션
- **인증**: `verify_token.py` - Supabase JWT 토큰 검증 모듈
- **시 생성**: `poem_generator_modern.py` - GPT-4o/GPT-5 지원하는 현대적 AI 시 생성 시스템
- **컨테이너화**: `Dockerfile` - Cloud Run 배포를 위한 다단계 Docker 빌드
- **배포**: `deploy.sh` - 자동화된 Google Cloud Run 배포 스크립트

## 개발 환경 설정

### 필수 요구사항
- Python 3.12+
- uv 패키지 매니저 (종속성 관리에 사용)

### 로컬 개발
```bash
# 종속성 설치
uv sync

# 개발 서버 실행
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# API 문서 접근
# http://localhost:8000/docs
```

### 테스트
제공된 HTTP 테스트 파일 사용:
```bash
# test_main.http를 사용하여 엔드포인트 테스트
# 오류 케이스를 포함한 포괄적인 엔드포인트 테스트 포함
```

## 배포

### Google Cloud Run 배포
```bash
# 자동화된 배포
./deploy.sh

# 수동 배포
gcloud run deploy clever-lemon-api \
    --source . \
    --region=asia-northeast3 \
    --platform=managed \
    --allow-unauthenticated
```

**프로덕션 URL**: https://clever-lemon-api-1043360097075.asia-northeast3.run.app/
- API 문서: https://clever-lemon-api-1043360097075.asia-northeast3.run.app/docs
- 헬스체크: https://clever-lemon-api-1043360097075.asia-northeast3.run.app/ping

### 컨테이너 빌드
```bash
# 로컬 컨테이너 테스트
docker build -t cloud-run-proj .
docker run -p 8080:8080 -e PORT=8080 cloud-run-proj
```

## 인증 아키텍처

Flutter Google 인증에서 제공하는 Supabase JWT 토큰과 함께 작동하도록 설계:

- **토큰 검증**: `verify_token.py`에서 Supabase JWT 검증 처리
- **JWKS 엔드포인트**: 키 검증을 위해 Supabase의 JWKS 엔드포인트 사용
- **지원 알고리즘**: ES256, RS256, EdDSA
- **통합 지점**: FastAPI 엔드포인트에서 미들웨어 통합 준비 완료

## API 구조

### 핵심 엔드포인트
- `GET /ping` - 헬스체크
- `POST /auth/register` - 액세스 토큰을 사용한 사용자 등록
- `POST /payments/approve` - 결제 처리
- `POST /poems/generate` - 크레딧 검증이 포함된 AI 시 생성 (30초 이상 응답 시간)

### 데이터 모델
- **UserCurrency**: coins, gems, premium_points
- **UserSettings**: font_size, theme, favorite_poet, poem_style 등
- **PoemRequest/Response**: 사용자 크레딧 검증이 포함된 다양한 스타일의 시 생성 처리

## 주요 구현 사항

### 시 생성 시스템
애플리케이션은 이중 API 지원하는 현대적인 시 생성 시스템을 사용합니다:
- **GPT-5 모델**: 추론 기능이 있는 OpenAI Responses API 사용
- **GPT-4o 모델**: 전통적인 Chat Completions API 사용
- **크레딧 시스템**: 각 시 생성은 사용자 계정에서 1 크레딧을 소모
- **오류 처리**: 상세한 로깅과 함께 포괄적인 JSON 파싱 실패 처리

### 크레딧 관리
- 시 생성은 처리 전 사용자 크레딧 검증이 필요
- 크레딧은 성공적인 시 생성 후에만 차감
- 실패한 생성은 크레딧을 소모하지 않음
- 데이터베이스 작업은 Supabase `users_credits` 테이블 사용

### 장시간 실행 작업
- 시 생성 엔드포인트는 30초 이상의 AI 처리를 시뮬레이션
- 프로덕션에서 비동기 처리를 위해 설계됨
- 프로덕션 사용을 위한 백그라운드 작업 처리 구현 고려

### 데이터베이스 통합
- **Supabase 통합**: 사용자 등록, 인증, 크레딧 관리에 활성화
- **모의 데이터**: 재화 및 설정에 대한 메모리 내 가짜 데이터베이스 사용 (`fake_user_currency`, `fake_user_settings`)
- **데이터베이스 테이블**: 
  - `users_credits`: user_id, credits, updated_at
- **향후 통합**: 모든 기능에 대한 전체 데이터베이스 마이그레이션 준비 완료

### 오류 처리
- 포괄적인 HTTP 예외 처리
- 사용자 대면 응답을 위한 한국어 오류 메시지
- 시 생성에서 JSON 파싱 실패에 대한 상세한 로깅

## 보안 고려사항

- 프로덕션 사용을 위한 JWT 검증 모듈 준비 완료
- 루트가 아닌 Docker 사용자 구성
- 민감한 구성을 위한 환경 변수 지원
- 배포 구성에서 HTTPS 강제 적용

## 구성

### 환경 변수
- `PORT` - 서버 포트 (기본값: 8080)
- `SUPABASE_URL` - Supabase 프로젝트 URL
- `SUPABASE_SERVICE_ROLE_KEY` - 데이터베이스 작업을 위한 Supabase 서비스 역할 키
- `SUPABASE_ANON_KEY` - Supabase 익명 키 (선택사항)
- `OPENAI_API_KEY` - 시 생성을 위한 OpenAI API 키
- `OPENAI_MODEL` - 사용할 OpenAI 모델 (기본값: gpt-5-mini-2025-08-07)

### Docker 구성
- Python 3.12 slim 기본 이미지
- 루트가 아닌 사용자 실행
- Cloud Run 배포에 최적화됨