# Python 3.12 슬림 이미지 사용
FROM python:3.12-slim

# 작업 디렉토리 설정
WORKDIR /app

# 파이썬 런타임 환경
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# pyproject.toml에서 requirements.txt 생성
COPY pyproject.toml ./
RUN pip install --no-cache-dir pip-tools && \
    pip-compile pyproject.toml --output-file requirements.txt

# 의존성 설치
RUN pip install --no-cache-dir -r requirements.txt

# 설치 확인
RUN python -c "import fastapi, uvicorn; print('Dependencies installed successfully')"

# 애플리케이션 코드 복사
COPY . .

# 비루트 사용자 생성 및 권한 설정
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 포트 설정
EXPOSE 8080

# 애플리케이션 실행
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]