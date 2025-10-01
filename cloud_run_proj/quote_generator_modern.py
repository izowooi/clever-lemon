# quote_generator_modern.py
from __future__ import annotations
from dataclasses import dataclass
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, Iterable, List
from openai import OpenAI
import os
import json
from dotenv import load_dotenv


# ======================
# 공통 DTO
# ======================
@dataclass(frozen=True)
class Prompt:
    system_prompt: str
    user_prompt: str


@dataclass(frozen=True)
class GenOptions:
    # 공통
    model: str

    # GPT-4o 전용
    temperature: Optional[float] = None
    max_tokens: Optional[int] = None

    # GPT-5 전용
    reasoning_effort: Optional[str] = None  # "low" | "medium" | "high"
    max_output_tokens: Optional[int] = None  # Responses API 상한


# ======================
# 프롬프트 빌더 (단일 책임)
# ======================
class KoreanQuotePromptBuilder:
    """
    오늘의 글귀 생성을 위한 프롬프트 빌더
    - system_prompt: 한국 문학과 명언에 정통한 작가 / 4개 작성 / 서로 다른 관점
    - user_prompt: style, author_style, keywords, length를 받아 본질 지침 생성
    """

    SYSTEM_PROMPT: str = (
        "당신은 한국 문학과 명언에 정통한 전문 작가입니다. "
        "주어진 조건에 맞춰 감동적이고 의미 있는 한국어 글귀를 정확히 4개 작성합니다. "
        "각 글귀는 독창적이고 서로 다른 관점과 표현을 사용해야 합니다. "
        "절대로 사과문이나 설명문으로 시작하지 마세요. "
        "오직 글귀만을 창작하세요."
    )

    @staticmethod
    def create_user_prompt(
            style: str,
            author_style: str,
            keywords: Iterable[str],
            length: str,
    ) -> str:
        """
        - style: 전체적인 분위기/톤(예: 희망적, 위로, 동기부여 등)
        - author_style: 참고 작가/문체(예: 김소월 풍, 괴테, 니체 등)
        - keywords: 반드시 자연스럽게 녹일 핵심 단어 목록
        - length: 길이 지침(예: '짧게 1-2문장', '보통 2-3문장', '길게 3-4문장' 등)
        """
        keywords_str: List[str] = [k.strip() for k in keywords if str(k).strip()]
        kw_str = ", ".join(keywords_str) if keywords_str else "제한 없음"

        prompt = f"""다음 조건에 맞춰 정확히 4개의 글귀를 창작하세요.

조건:
• 성향: {style}
• 작가 스타일: {author_style}
• 포함 단어: '{kw_str}'
• 길이: {length}

창작 지침:
• 각 글귀는 1-3문장으로 구성된 짧고 임팩트 있는 메시지여야 합니다
• 지정된 단어들을 자연스럽게 녹여내세요
• {author_style} 작가의 문체와 정서를 반영하세요
• 은유와 비유를 적절히 활용하세요
• 독자에게 영감과 위로를 주는 내용이어야 합니다
• 기억하기 쉽고 공유하고 싶은 문장으로 작성하세요
• 4개의 글귀는 서로 다른 관점과 표현을 사용하세요

중요한 제약사항:
• 절대로 "죄송합니다", "~할 수는 없지만", "~해드립니다" 같은 사과나 설명으로 시작하지 마세요
• 직접적으로 글귀만 창작하세요
• 메타 언급이나 부가 설명은 금지합니다

최종 출력은 반드시 아래 JSON 형식만 사용하세요:

{{
  "quote1": "첫 번째 글귀 내용...",
  "quote2": "두 번째 글귀 내용...",
  "quote3": "세 번째 글귀 내용...",
  "quote4": "네 번째 글귀 내용..."
}}"""

        return prompt


# ======================
# 어댑터 인터페이스
# ======================
class BaseModelAdapter(ABC):
    def __init__(self, client: OpenAI, model: str):
        self.client = client
        self.model = model

    @abstractmethod
    def generate(self, prompt: Prompt, opt: GenOptions) -> str: ...


# ======================
# GPT-4o 어댑터 (Chat Completions)
# ======================
class GPT4oAdapter(BaseModelAdapter):
    def generate(self, prompt: Prompt, opt: GenOptions) -> str:
        kwargs: Dict[str, Any] = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": prompt.system_prompt},
                {"role": "user", "content": prompt.user_prompt},
            ],
        }
        if opt.temperature is not None:
            kwargs["temperature"] = opt.temperature
        if opt.max_tokens is not None:
            kwargs["max_tokens"] = opt.max_tokens

        resp = self.client.chat.completions.create(**kwargs)
        return resp.choices[0].message.content or ""


# ======================
# GPT-5 어댑터 (Responses API)
# ======================
class GPT5Adapter(BaseModelAdapter):
    def generate(self, prompt: Prompt, opt: GenOptions) -> str:
        kwargs: Dict[str, Any] = {
            "model": self.model,
            "instructions": prompt.system_prompt,
            "input": prompt.user_prompt,
        }
        if opt.reasoning_effort:
            kwargs["reasoning"] = {"effort": opt.reasoning_effort}
        if opt.max_output_tokens is not None:
            kwargs["max_output_tokens"] = opt.max_output_tokens

        resp = self.client.responses.create(**kwargs)
        return getattr(resp, "output_text", None) or ""


# ======================
# 어댑터 팩토리 (OCP)
# ======================
class ModelAdapterFactory:
    @staticmethod
    def create(client: OpenAI, model: str) -> BaseModelAdapter:
        name = model.lower()
        if name.startswith("gpt-5"):
            return GPT5Adapter(client, model)
        if name.startswith("gpt-4o"):
            return GPT4oAdapter(client, model)
        raise ValueError(f"Unsupported model family: {model}")


# ======================
# 파싱/출력용 DTO
# ======================
@dataclass
class Quote:
    index: int
    text: str

    @property
    def word_count(self) -> int:
        return len(self.text.split())


@dataclass
class ParseResult:
    quotes: List[Quote]
    raw: str

    def to_json(self) -> str:
        return json.dumps(
            {
                "quotes": [
                    {"index": q.index, "word_count": q.word_count, "text": q.text}
                    for q in self.quotes
                ],
                "raw": self.raw,
            },
            ensure_ascii=False,
            indent=2,
        )


# ======================
# 퍼사드: 글귀 생성 유스케이스 (SRP)
# ======================
class QuoteGenerator:
    def __init__(self, client: Optional[OpenAI] = None, api_key: str = None):
        # 환경변수 로드
        load_dotenv()

        # OpenAI 클라이언트 설정
        if client:
            self.client = client
        else:
            # API 키 설정
            if api_key is None:
                api_key = os.getenv('OPENAI_API_KEY')

            if not api_key:
                raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다.")

            self.client = OpenAI(api_key=api_key)

        self.system_prompt = KoreanQuotePromptBuilder.SYSTEM_PROMPT

    def _build_prompt(
            self,
            style: str,
            author_style: str,
            keywords: Iterable[str],
            length: str,
    ) -> Prompt:
        user_prompt = KoreanQuotePromptBuilder.create_user_prompt(
            style=style,
            author_style=author_style,
            keywords=keywords,
            length=length,
        )
        return Prompt(system_prompt=self.system_prompt, user_prompt=user_prompt)

    def generate_quotes(
            self,
            style: str,
            author_style: str,
            keywords: Iterable[str],
            length: str,
            opt: GenOptions,
    ) -> str:
        adapter = ModelAdapterFactory.create(self.client, opt.model)
        prompt = self._build_prompt(style, author_style, keywords, length)
        return adapter.generate(prompt, opt)

    def _validate_quote_content(self, quote: str) -> bool:
        """글귀 내용이 올바른지 검증 (사과문이나 메타 언급 체크)"""
        if not quote or not quote.strip():
            return False

        # 금지된 시작 패턴들
        forbidden_starts = [
            "죄송합니다",
            "죄송하지만",
            "미안합니다",
            "할 수는 없지만",
            "해드립니다",
            "써드립니다",
            "작성해드립니다",
            "만들어드립니다",
            "그대로 재현할 수는 없지만",
            "정확한 문체를 그대로",
            "님의 정확한",
            "정확히 따라할 수는"
        ]

        quote_start = quote.strip()[:50].lower()  # 첫 50자만 체크

        for forbidden in forbidden_starts:
            if forbidden.lower() in quote_start:
                return False

        return True

    # ---------- 파싱 ----------
    def parse_response(self, content: str, style: str, author_style: str, keywords: List[str], length: str) -> Dict:
        """OpenAI 응답 파싱"""
        try:
            # JSON 코드 블록 제거
            content = content.replace('```json', '').replace('```', '').strip()

            # JSON 파싱
            parsed = json.loads(content)

            quotes = [
                parsed.get("quote1", ""),
                parsed.get("quote2", ""),
                parsed.get("quote3", ""),
                parsed.get("quote4", "")
            ]

            # 각 글귀의 내용을 검증
            for i, quote in enumerate(quotes, 1):
                if not self._validate_quote_content(quote):
                    print(f"⚠️ 글귀 {i}번에서 부적절한 내용 감지: {quote[:100]}...")
                    return {
                        "success": False,
                        "error": "AI가 부적절한 응답을 생성했습니다. 다시 시도해주세요.",
                        "error_code": "INAPPROPRIATE_RESPONSE",
                        "request": {
                            "style": style,
                            "author_style": author_style,
                            "keywords": keywords,
                            "length": length
                        },
                        "quotes": []
                    }

            return {
                "success": True,
                "request": {
                    "style": style,
                    "author_style": author_style,
                    "keywords": keywords,
                    "length": length
                },
                "quotes": quotes
            }

        except json.JSONDecodeError as e:
            print(f"⚠️ JSON 파싱 실패: {e}")
            print(f"📋 원본 응답 길이: {len(content)}")
            print(f"📝 원본 응답 내용:")
            print("=" * 50)
            print(repr(content))
            print("=" * 50)
            if content.strip() == "":
                print("⚠️ 빈 응답이 수신되었습니다!")
            else:
                print(f"📄 첫 100자: {content[:100]}")
                print(f"📄 마지막 100자: {content[-100:]}")

            return {
                "success": False,
                "error": "AI 응답 파싱에 실패했습니다. 다시 시도해주세요.",
                "error_code": "PARSING_FAILED",
                "request": {
                    "style": style,
                    "author_style": author_style,
                    "keywords": keywords,
                    "length": length
                },
                "quotes": []
            }

    def display_quotes(self, result: Dict) -> None:
        """생성된 글귀들을 보기 좋게 출력"""
        if not result["success"]:
            print(f"⚠️ 글귀 생성 실패: {result.get('error', '알 수 없는 오류')}")
            return

        print("\n" + "=" * 60)
        print("✨ 오늘의 글귀 모음 ✨")
        print("=" * 60)

        request_info = result["request"]
        print(f"📌 성향: {request_info['style']}")
        print(f"✍️  작가 스타일: {request_info['author_style']}")
        print(f"🔑 포함 단어: {', '.join(request_info['keywords'])}")
        print(f"📏 길이: {request_info['length']}")
        print("-" * 60)

        for i, quote in enumerate(result["quotes"], 1):
            print(f"\n【 글귀 {i} 】")
            print("-" * 40)
            print(f"  {quote}")
            print("-" * 40)

        print(f"\n✅ 총 {len(result['quotes'])}개의 글귀가 생성되었습니다.")


# ======================
# 사용 예시
# ======================
if __name__ == "__main__":
    """
    OPENAI_API_KEY 환경변수가 설정되어 있어야 합니다.
    """

    gen = QuoteGenerator()

    style = "희망적이고 위로가 되는"
    author_style = "헤르만 헤세"
    keywords = ["봄", "시작", "용기"]
    length = "짧게 1-2문장"

    # 1) GPT-5 계열 (Responses API)
    quotes_v5 = gen.generate_quotes(
        style=style,
        author_style=author_style,
        keywords=keywords,
        length=length,
        opt=GenOptions(
            model="gpt-5-mini-2025-08-07",
            reasoning_effort="low",
            max_output_tokens=1024,
        ),
    )
    print("\n[gpt-5 결과]\n")
    print(quotes_v5)

    parsed_v5 = gen.parse_response(quotes_v5, style, author_style, keywords, length)
    gen.display_quotes(parsed_v5)

    print("\n" + "=" * 60)
    print("📊 JSON 결과")
    print("=" * 60)
    print(json.dumps(parsed_v5, ensure_ascii=False, indent=2))