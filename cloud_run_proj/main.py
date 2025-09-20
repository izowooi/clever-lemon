from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import asyncio
from datetime import datetime
import os
from dotenv import load_dotenv
from supabase import create_client, Client
from verify_token import verify_and_decode_supabase_jwt
from poem_generator_modern import PoemGenerator, GenOptions

load_dotenv()

# Supabase 클라이언트 설정
supabase_url = os.getenv("SUPABASE_URL")
supabase_service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not supabase_url or not supabase_service_key:
    print("경고: Supabase 환경변수가 설정되지 않았습니다.")
    supabase = None
else:
    supabase: Client = create_client(supabase_url, supabase_service_key)

# PoemGenerator 인스턴스 초기화 (전역으로 재사용)
try:
    poem_generator = PoemGenerator()
    print("✅ PoemGenerator 초기화 완료")
except Exception as e:
    print(f"⚠️ PoemGenerator 초기화 실패: {e}")
    poem_generator = None

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
    user_id: str  # 사용자 ID
    style: str  # 성향 (예: "낭만적인", "우울한", "희망적인")
    author_style: str  # 작가 스타일 (예: "김소월", "윤동주")
    keywords: List[str]  # 포함할 단어들 (3-5개)
    length: str  # 길이 (예: "8행", "16행", "보통")

class PoemResponse(BaseModel):
    success: bool
    request: dict  # 요청 정보
    poems: List[str]  # 생성된 시들 (제목 포함)
    generation_time: Optional[float] = None
    remaining_credits: Optional[int] = None
    error: Optional[str] = None

class TokenRequest(BaseModel):
    token: str

class TokenResponse(BaseModel):
    user_id: str
    role: Optional[str] = None
    email: Optional[str] = None
    exp: int
    message: str

class UserRegistrationTestRequest(BaseModel):
    user_id: str
    initial_credits: Optional[int] = 100

class UserRegistrationRequest(BaseModel):
    access_token: str

class UserRegistrationResponse(BaseModel):
    success: bool
    user_id: str
    credits: int
    message: str
    created_at: Optional[str] = None

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


# 회원가입 (실제용) - access_token으로 등록
@app.post("/auth/register", response_model=UserRegistrationResponse)
async def register_user(request: UserRegistrationRequest):
    """실제용: access_token을 검증하고 회원가입 처리"""
    if not supabase:
        raise HTTPException(
            status_code=500,
            detail="Supabase 클라이언트가 설정되지 않았습니다"
        )
    
    try:
        # JWT 토큰 검증
        claims = verify_and_decode_supabase_jwt(request.access_token)
        user_id = claims["sub"]
        
        # 기존 사용자 확인
        existing_user = supabase.table("users_credits").select("*").eq("user_id", user_id).execute()

        if existing_user.data:
            user_data = existing_user.data[0]
            total_credits = user_data.get("free_credits", 0) + user_data.get("paid_credits", 0)
            return UserRegistrationResponse(
                success=True,
                user_id=user_data["user_id"],
                credits=total_credits,
                message="이미 등록된 사용자입니다",
                created_at=user_data.get("updated_at")
            )

        # 새 사용자 등록
        initial_credits = 100  # 기본 크레딧
        result = supabase.table("users_credits").insert({
            "user_id": user_id,
            "free_credits": initial_credits,
            "paid_credits": 0,
            "updated_at": datetime.now().isoformat()
        }).execute()

        if result.data:
            user_data = result.data[0]
            total_credits = user_data.get("free_credits", 0) + user_data.get("paid_credits", 0)
            return UserRegistrationResponse(
                success=True,
                user_id=user_data["user_id"],
                credits=total_credits,
                message="회원가입이 성공적으로 완료되었습니다",
                created_at=user_data.get("updated_at")
            )
        else:
            raise HTTPException(
                status_code=500,
                detail="데이터베이스 등록에 실패했습니다"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"회원가입 처리 중 오류가 발생했습니다: {str(e)}"
        )


# 결제 승인
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

# 크레딧 검증 함수
def validate_user_credit(user_id: str) -> int:
    """사용자의 크레딧을 확인하고 반환합니다"""
    if not supabase:
        raise HTTPException(
            status_code=500,
            detail="Supabase 클라이언트가 설정되지 않았습니다"
        )

    try:
        user_data = supabase.table("users_credits").select("*").eq("user_id", user_id).execute()

        if not user_data.data:
            raise HTTPException(
                status_code=404,
                detail="등록되지 않은 사용자입니다"
            )

        user_info = user_data.data[0]
        free_credits = user_info.get("free_credits", 0)
        paid_credits = user_info.get("paid_credits", 0)
        total_credits = free_credits + paid_credits

        if total_credits <= 0:
            raise HTTPException(
                status_code=400,
                detail="크레딧이 부족합니다. 크레딧을 충전해주세요"
            )

        return total_credits

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"크레딧 확인 중 오류가 발생했습니다: {str(e)}"
        )

# 크레딧 차감 함수
def deduct_user_credit(user_id: str) -> int:
    """사용자의 크레딧을 1 차감하고 남은 크레딧을 반환합니다 (free_credits 우선 소모)"""
    if not supabase:
        raise HTTPException(
            status_code=500,
            detail="Supabase 클라이언트가 설정되지 않았습니다"
        )

    try:
        # 현재 크레딧 조회
        current_credits_result = supabase.table("users_credits").select("*").eq("user_id", user_id).execute()
        user_info = current_credits_result.data[0]
        free_credits = user_info.get("free_credits", 0)
        paid_credits = user_info.get("paid_credits", 0)

        # free_credits 우선 차감
        if free_credits > 0:
            new_free_credits = free_credits - 1
            new_paid_credits = paid_credits
        elif paid_credits > 0:
            new_free_credits = free_credits
            new_paid_credits = paid_credits - 1
        else:
            raise HTTPException(
                status_code=400,
                detail="크레딧이 부족합니다"
            )

        # 크레딧 업데이트
        result = supabase.table("users_credits").update({
            "free_credits": new_free_credits,
            "paid_credits": new_paid_credits,
            "updated_at": datetime.now().isoformat()
        }).eq("user_id", user_id).execute()

        if result.data:
            updated_user = result.data[0]
            return updated_user.get("free_credits", 0) + updated_user.get("paid_credits", 0)
        else:
            raise HTTPException(
                status_code=500,
                detail="크레딧 차감에 실패했습니다"
            )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"크레딧 차감 중 오류가 발생했습니다: {str(e)}"
        )

# 6. 실제 AI 시 생성
@app.post("/poems/generate", response_model=PoemResponse)
async def generate_poems(poem_request: PoemRequest):
    """OpenAI를 이용해 4편의 시를 생성합니다 (크레딧 검증 포함)"""
    if not poem_generator:
        raise HTTPException(
            status_code=500,
            detail="시 생성기가 초기화되지 않았습니다. OpenAI API 키를 확인해주세요."
        )
    
    # 크레딧 검증
    validate_user_credit(poem_request.user_id)
    
    start_time = datetime.now()
    
    try:
        # 환경변수에서 모델 정보 가져오기
        model = os.getenv('OPENAI_MODEL', 'gpt-5-mini-2025-08-07')
        
        # 모델에 따른 옵션 설정
        if model.startswith('gpt-5'):
            # GPT-5 계열: Responses API
            gen_options = GenOptions(
                model=model,
                reasoning_effort="low",
                max_output_tokens=2048
            )
        else:
            # GPT-4o 계열: Chat Completions API
            gen_options = GenOptions(
                model=model,
                temperature=0.9,
                max_tokens=2000
            )
        
        # PoemGenerator를 사용하여 시 생성 (원시 텍스트 반환)
        raw_result = await asyncio.to_thread(
            poem_generator.generate_poems,
            style=poem_request.style,
            author_style=poem_request.author_style,
            keywords=poem_request.keywords,
            length=poem_request.length,
            opt=gen_options
        )
        
        # 응답 파싱하여 구조화된 결과 생성
        parsed_result = poem_generator.parse_response(
            raw_result,
            poem_request.style,
            poem_request.author_style,
            poem_request.keywords,
            poem_request.length
        )
        
        # 파싱 결과 확인 - 실패한 경우 크레딧 차감하지 않고 에러 응답
        if not parsed_result.get("success", False):
            end_time = datetime.now()
            generation_time = (end_time - start_time).total_seconds()
            parsed_result["generation_time"] = generation_time
            
            # 부적절한 응답이나 파싱 실패 시 422 상태코드로 응답
            raise HTTPException(
                status_code=422,
                detail={
                    "message": parsed_result.get("error", "시 생성에 실패했습니다"),
                    "error_code": parsed_result.get("error_code", "GENERATION_FAILED"),
                    "generation_time": generation_time,
                    "retry_recommended": True
                }
            )
        
        # 시 생성 성공 후 크레딧 차감
        remaining_credits = deduct_user_credit(poem_request.user_id)
        
        end_time = datetime.now()
        generation_time = (end_time - start_time).total_seconds()
        
        # 생성 시간과 남은 크레딧 정보 추가
        parsed_result["generation_time"] = generation_time
        parsed_result["remaining_credits"] = remaining_credits
        
        return PoemResponse(**parsed_result)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"시 생성 중 오류가 발생했습니다: {str(e)}"
        )
