from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import asyncio
from datetime import datetime
from verify_token import verify_and_decode_supabase_jwt

app = FastAPI(title="시 생성 API", version="1.0.0")

# Pydantic 모델 정의
class UserCurrency(BaseModel):
    user_id: str
    coins: int
    gems: int
    premium_points: int

class UserSettings(BaseModel):
    user_id: str
    font_size: int = 14
    app_theme_color: str = "blue"
    favorite_poet: str = "윤동주"
    poem_style: str = "서정적"
    poem_length: str = "보통"
    ai_model: str = "gpt-4"

class UserSettingsUpdate(BaseModel):
    font_size: Optional[int] = None
    app_theme_color: Optional[str] = None
    favorite_poet: Optional[str] = None
    poem_style: Optional[str] = None
    poem_length: Optional[str] = None
    ai_model: Optional[str] = None

class PaymentInfo(BaseModel):
    payment_id: str
    amount: int
    currency_type: str  # "coins", "gems", "premium_points"
    payment_method: str

class PaymentRequest(BaseModel):
    user_id: str
    payment_info: PaymentInfo

class PoemRequest(BaseModel):
    style: str  # 서정적, 서사적, 자유시 등
    poet: str  # 좋아하는 작가
    theme_words: List[str]  # 3-5개의 테마 단어
    length: str  # 짧은 시, 보통, 긴 시
    ai_model: str

class Poem(BaseModel):
    title: str
    content: str
    style: str

class PoemResponse(BaseModel):
    poems: List[Poem]
    generation_time: float
    ai_model_used: str

class TokenRequest(BaseModel):
    token: str

class TokenResponse(BaseModel):
    user_id: str
    role: Optional[str] = None
    email: Optional[str] = None
    exp: int
    message: str

# 더미 데이터베이스 (실제 구현에서는 데이터베이스 사용)
fake_user_currency = {
    "user123": {"coins": 1000, "gems": 50, "premium_points": 25},
    "user456": {"coins": 2500, "gems": 100, "premium_points": 75},
}

fake_user_settings = {
    "user123": {
        "font_size": 16,
        "app_theme_color": "dark",
        "favorite_poet": "김소월",
        "poem_style": "서정적",
        "poem_length": "짧은 시",
        "ai_model": "gpt-4"
    },
    "user456": {
        "font_size": 14,
        "app_theme_color": "light",
        "favorite_poet": "윤동주",
        "poem_style": "자유시",
        "poem_length": "보통",
        "ai_model": "claude-3"
    }
}

@app.get("/")
async def root():
    return {"message": "오늘도 힘내세요."}

# 1. Ping 엔드포인트
@app.get("/ping")
async def ping():
    """서버 상태 확인을 위한 ping 엔드포인트"""
    return {
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "server": "poem-generation-api",
        "version": "1.0.0"
    }

# 7. 토큰 인증 및 검증
@app.post("/auth/verify", response_model=TokenResponse)
async def verify_token(token_request: TokenRequest):
    """Supabase JWT 토큰을 검증하고 사용자 정보를 반환합니다"""
    try:
        claims = verify_and_decode_supabase_jwt(token_request.token)
        
        return TokenResponse(
            user_id=claims["sub"],
            role=claims.get("role"),
            email=claims.get("email"),
            exp=claims["exp"],
            message="토큰 검증이 성공적으로 완료되었습니다"
        )
    except Exception as e:
        raise HTTPException(
            status_code=401,
            detail=f"토큰 검증 실패: {str(e)}"
        )

# 2. 유저 재화 정보 조회
@app.get("/users/{user_id}/currency", response_model=UserCurrency)
async def get_user_currency(user_id: str):
    """유저의 재화 정보를 조회합니다"""
    if user_id not in fake_user_currency:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    currency_data = fake_user_currency[user_id]
    return UserCurrency(
        user_id=user_id,
        coins=currency_data["coins"],
        gems=currency_data["gems"],
        premium_points=currency_data["premium_points"]
    )

# 3. 유저 설정 정보 조회
@app.get("/users/{user_id}/settings", response_model=UserSettings)
async def get_user_settings(user_id: str):
    """유저의 설정 정보를 조회합니다"""
    if user_id not in fake_user_settings:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    settings_data = fake_user_settings[user_id]
    return UserSettings(
        user_id=user_id,
        **settings_data
    )

# 4. 유저 설정 정보 갱신
@app.put("/users/{user_id}/settings", response_model=UserSettings)
async def update_user_settings(user_id: str, settings_update: UserSettingsUpdate):
    """유저의 설정 정보를 갱신합니다"""
    if user_id not in fake_user_settings:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    # 기존 설정 가져오기
    current_settings = fake_user_settings[user_id].copy()
    
    # 업데이트할 필드만 변경
    update_data = settings_update.dict(exclude_unset=True)
    current_settings.update(update_data)
    
    # 더미 데이터베이스 업데이트
    fake_user_settings[user_id] = current_settings
    
    return UserSettings(
        user_id=user_id,
        **current_settings
    )

# 5. 결제 승인
@app.post("/payments/approve")
async def approve_payment(payment_request: PaymentRequest):
    """결제를 승인하고 재화를 지급합니다"""
    user_id = payment_request.user_id
    payment_info = payment_request.payment_info
    
    # 사용자 존재 확인
    if user_id not in fake_user_currency:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    # 결제 처리 시뮬레이션 (실제로는 결제 게이트웨이 연동)
    await asyncio.sleep(1)  # 결제 처리 시간 시뮬레이션
    
    # 재화 지급
    currency_type = payment_info.currency_type
    amount = payment_info.amount
    
    if currency_type in fake_user_currency[user_id]:
        fake_user_currency[user_id][currency_type] += amount
    else:
        raise HTTPException(status_code=400, detail="잘못된 재화 타입입니다")
    
    return {
        "status": "approved",
        "payment_id": payment_info.payment_id,
        "user_id": user_id,
        "amount_added": amount,
        "currency_type": currency_type,
        "new_balance": fake_user_currency[user_id][currency_type],
        "timestamp": datetime.now().isoformat()
    }

# 6. 시 생성 (30초 이상 소요)
@app.post("/poems/generate", response_model=PoemResponse)
async def generate_poems(poem_request: PoemRequest):
    """AI를 이용해 4가지 스타일의 시를 생성합니다 (시간이 오래 걸립니다)"""
    start_time = datetime.now()
    
    # AI 시 생성 시뮬레이션 (실제로는 AI 모델 호출)
    await asyncio.sleep(32)  # 30초 이상 시뮬레이션
    
    # 더미 시 데이터 생성
    theme_words_str = ", ".join(poem_request.theme_words)
    
    poems = [
        Poem(
            title=f"서정적인 {poem_request.poet} 스타일의 시",
            content=f"""달빛이 흐르는 밤에
{theme_words_str}가 속삭이네
마음 깊은 곳에서 울려오는
그리움의 노래

({poem_request.poet} 스타일, {poem_request.length})""",
            style="서정적"
        ),
        Poem(
            title=f"서사적인 {poem_request.poet} 스타일의 시",
            content=f"""옛날 어느 마을에
{theme_words_str}가 살았다네
긴 여행을 떠나며
새로운 이야기를 써내려가네

({poem_request.poet} 스타일, {poem_request.length})""",
            style="서사적"
        ),
        Poem(
            title=f"자유시 {poem_request.poet} 스타일",
            content=f"""{theme_words_str}
흩어져
모여
다시 흩어지고

자유롭게
흘러가는
시간 속에서

({poem_request.poet} 스타일, {poem_request.length})""",
            style="자유시"
        ),
        Poem(
            title=f"현대적 {poem_request.poet} 스타일의 시",
            content=f"""스마트폰 화면에 비친
{theme_words_str}의 모습
디지털 세상 속에서도
변하지 않는 마음

({poem_request.poet} 스타일, {poem_request.length})""",
            style="현대적"
        )
    ]
    
    end_time = datetime.now()
    generation_time = (end_time - start_time).total_seconds()
    
    return PoemResponse(
        poems=poems,
        generation_time=generation_time,
        ai_model_used=poem_request.ai_model
    )
