# poem_generator_modern.py
from __future__ import annotations
from dataclasses import dataclass
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, Iterable, List
from openai import OpenAI
import os
import re
import json
import sys
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
class KoreanPoemPromptBuilder:
   """
   simple_poem_generator.py의 의도를 보존:
   - system_prompt: 한국 문학에 정통한 시인 / 4편 작성 / 서로 다른 관점
   - user_prompt: style, author_style, keywords, length를 받아 본질 지침 생성
   """

   SYSTEM_PROMPT: str = (
       "당신은 한국 문학에 정통한 전문 시인입니다. "
       "주어진 조건에 맞춰 감동적이고 아름다운 한국어 시를 정확히 4편 작성합니다. "
       "각 시는 독창적이고 서로 다른 관점과 표현을 사용해야 합니다. "
       "절대로 사과문이나 설명문으로 시작하지 마세요. "
       "오직 시 작품만을 창작하세요."
   )

   @staticmethod
   def create_user_prompt(
       style: str,
       author_style: str,
       keywords: Iterable[str],
       length: str,
   ) -> str:
       """
       - style: 전체적인 분위기/톤(예: 서정적, 미니멀, 초현실 등)
       - author_style: 참고 작가/문체(예: 김소월 풍, 이육사의 결 등)
       - keywords: 반드시 자연스럽게 녹일 핵심 단어 목록
       - length: 길이 지침(예: '각 시 6~10행', '짧게 4~6행', '중간 길이' 등)
       """
       keywords_str: List[str] = [k.strip() for k in keywords if str(k).strip()]
       kw_str = ", ".join(keywords_str) if keywords_str else "제한 없음"

       prompt = f"""다음 조건에 맞춰 정확히 4편의 시를 창작하세요.

조건:
• 성향: {style}
• 작가 스타일: {author_style}  
• 포함 단어: '{kw_str}'
• 길이: {length}

창작 지침:
• 각 시는 반드시 제목으로 시작하세요
• 지정된 단어들을 자연스럽게 녹여내세요
• {author_style} 작가의 문체와 정서를 반영하세요
• 은유와 상징을 적절히 활용하세요
• 감정과 정서가 잘 전달되도록 작성하세요
• 리듬감과 운율을 고려하세요
• 4편의 시는 서로 다른 관점과 표현을 사용하세요

중요한 제약사항:
• 절대로 "죄송합니다", "~할 수는 없지만", "~해드립니다" 같은 사과나 설명으로 시작하지 마세요
• 직접적으로 시 작품만 창작하세요
• 메타 언급이나 부가 설명은 금지합니다

최종 출력은 반드시 아래 JSON 형식만 사용하세요:

{{
  "poem1": "첫 번째 시 제목\n\n첫 번째 시 본문...",
  "poem2": "두 번째 시 제목\n\n두 번째 시 본문...",
  "poem3": "세 번째 시 제목\n\n세 번째 시 본문...",
  "poem4": "네 번째 시 제목\n\n네 번째 시 본문..."
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
           # Responses API 권장 필드 매핑:
           # - system 성격 → instructions
           # - user 성격  → input
           "instructions": prompt.system_prompt,
           "input": prompt.user_prompt,
       }
       if opt.reasoning_effort:
           kwargs["reasoning"] = {"effort": opt.reasoning_effort}
       if opt.max_output_tokens is not None:
           kwargs["max_output_tokens"] = opt.max_output_tokens

       resp = self.client.responses.create(**kwargs)
       # Python SDK: output_text가 있으면 가장 깔끔
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
class Poem:
   index: int
   text: str

   @property
   def lines(self) -> List[str]:
       return [ln.rstrip() for ln in self.text.splitlines() if ln.strip() != ""]

   @property
   def line_count(self) -> int:
       return len(self.lines)


@dataclass
class ParseResult:
   poems: List[Poem]
   raw: str

   def to_json(self) -> str:
       return json.dumps(
           {
               "poems": [
                   {"index": p.index, "line_count": p.line_count, "text": p.text}
                   for p in self.poems
               ],
               "raw": self.raw,
           },
           ensure_ascii=False,
           indent=2,
       )


# ======================
# 퍼사드: 시 생성 유스케이스 (SRP)
# ======================
class PoemGenerator:
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
       
       self.system_prompt = KoreanPoemPromptBuilder.SYSTEM_PROMPT

   def _build_prompt(
       self,
       style: str,
       author_style: str,
       keywords: Iterable[str],
       length: str,
   ) -> Prompt:
       user_prompt = KoreanPoemPromptBuilder.create_user_prompt(
           style=style,
           author_style=author_style,
           keywords=keywords,
           length=length,
       )
       return Prompt(system_prompt=self.system_prompt, user_prompt=user_prompt)

   def generate_poems(
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


   def _validate_poem_content(self, poem: str) -> bool:
       """시 내용이 올바른지 검증 (사과문이나 메타 언급 체크)"""
       if not poem or not poem.strip():
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
       
       poem_start = poem.strip()[:50].lower()  # 첫 50자만 체크
       
       for forbidden in forbidden_starts:
           if forbidden.lower() in poem_start:
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
           
           poems = [
               parsed.get("poem1", ""),
               parsed.get("poem2", ""),
               parsed.get("poem3", ""),
               parsed.get("poem4", "")
           ]
           
           # 각 시의 내용을 검증
           for i, poem in enumerate(poems, 1):
               if not self._validate_poem_content(poem):
                   print(f"⚠️ 시 {i}번에서 부적절한 내용 감지: {poem[:100]}...")
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
                       "poems": []
                   }

           return {
               "success": True,
               "request": {
                   "style": style,
                   "author_style": author_style,
                   "keywords": keywords,
                   "length": length
               },
               "poems": poems
           }

       except json.JSONDecodeError as e:
           print(f"⚠️ JSON 파싱 실패: {e}")
           print(f"📋 원본 응답 길이: {len(content)}")
           print(f"📝 원본 응답 내용:")
           print("=" * 50)
           print(repr(content))  # repr로 출력하여 숨겨진 문자들까지 보이도록 함
           print("=" * 50)
           if content.strip() == "":
               print("⚠️ 빈 응답이 수신되었습니다!")
           else:
               print(f"📄 첫 100자: {content[:100]}")
               print(f"📄 마지막 100자: {content[-100:]}")

           # JSON 파싱 실패 시 실패 응답 반환
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
               "poems": []
           }

   def _fallback_parse(self, content: str, style: str, author_style: str, keywords: List[str], length: str) -> Dict:
       """JSON 파싱 실패시 대안 파싱"""
       try:
           # 시들을 구분하는 패턴으로 분할
           poems = []
           lines = content.split('\n')
           current_poem = []
           
           for line in lines:
               line = line.strip()
               if line and not line.startswith('"') and not line.startswith('{') and not line.startswith('}'):
                   current_poem.append(line)
               elif current_poem and len(poems) < 4:
                   poems.append('\n'.join(current_poem))
                   current_poem = []
           
           # 마지막 시 추가
           if current_poem and len(poems) < 4:
               poems.append('\n'.join(current_poem))
           
           # 4편이 안 되면 원본 텍스트를 4등분
           while len(poems) < 4:
               poems.append(f"시 {len(poems) + 1} (파싱 실패)")
           
           return {
               "success": True,
               "request": {
                   "style": style,
                   "author_style": author_style,
                   "keywords": keywords,
                   "length": length
               },
               "poems": poems[:4]  # 최대 4편만
           }
           
       except Exception as e:
           print(f"❌ 대안 파싱 실패: {e}")
           return {
               "success": False,
               "error": f"파싱 실패: {str(e)}",
               "request": {
                   "style": style,
                   "author_style": author_style,
                   "keywords": keywords,
                   "length": length
               },
               "poems": []
           }


   def display_poems(self, result: Dict) -> None:
       """생성된 시들을 보기 좋게 출력"""
       if not result["success"]:
           print(f"⚠️ 시 생성 실패: {result.get('error', '알 수 없는 오류')}")
           return

       print("\n" + "=" * 60)
       print("🌸 생성된 시 모음 🌸")
       print("=" * 60)

       request_info = result["request"]
       print(f"📝 성향: {request_info['style']}")
       print(f"✍️  작가 스타일: {request_info['author_style']}")
       print(f"🔑 포함 단어: {', '.join(request_info['keywords'])}")
       print(f"📏 길이: {request_info['length']}")
       print("-" * 60)

       for i, poem in enumerate(result["poems"], 1):
           print(f"\n【 시 {i} 】")
           print("-" * 40)
           print(poem)
           print("-" * 40)

       print(f"\n✅ 총 {len(result['poems'])}편의 시가 생성되었습니다.")


# ======================
# 사용 예시
# ======================
if __name__ == "__main__":
   """
   OPENAI_API_KEY 환경변수가 설정되어 있어야 합니다.
   """

   gen = PoemGenerator()

   style = "낭만적인"
   author_style = "김소월"
   keywords = ["꽃", "바람", "향기"]
   length = "8행"

   # 1) GPT-5 계열 (Responses API)
   poems_v5 = gen.generate_poems(
       style=style,
       author_style=author_style,
       keywords=keywords,
       length=length,
       opt=GenOptions(
           model="gpt-5-mini-2025-08-07",
           reasoning_effort="low",      # "low" | "medium" | "high"
           max_output_tokens=2048,       # GPT-5 상한
       ),
   )
   print("\n[gpt-5]\n")
   print(poems_v5)

   parsed_v5 = gen.parse_response(poems_v5, style, author_style, keywords, length)
   gen.display_poems(parsed_v5)


   # 2) GPT-4o 계열 (Chat Completions)
   # poems_4o = gen.generate_poems(
   #     style=style,
   #     author_style=author_style,
   #     keywords=keywords,
   #     length=length,
   #     opt=GenOptions(
   #         model="gpt-4o-mini",
   #         temperature=0.9,
   #         max_tokens=2000,
   #     ),
   # )
   #
   # print("\n[gpt-4o]\n")
   # print(poems_4o)
   #
   # # ====== (B) GPT-4o 계열 ======
   # opt_4o = GenOptions(
   #     model="gpt-4o-mini",
   #     temperature=0.9,
   #     max_tokens=2000,
   # )
   # poems_text_4o = gen.generate_poems(style, author_style, keywords, length, opt_4o)
   # parsed_4o = gen.parse_response(poems_text_4o, style, author_style, keywords, length)
   # gen.display_poems(parsed_4o)

   # print("\n" + "=" * 60)
   # print("📊 JSON 결과 (gpt-4o)")
   # print("=" * 60)
   # print(json.dumps(parsed_4o, ensure_ascii=False, indent=2))

