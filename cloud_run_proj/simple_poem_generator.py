# simple_poem_generator.py
"""
OpenAI API를 활용한 간단한 시 생성 서비스
openai_service.py의 구조를 참고하여 간단하게 구현
"""

import json
import os
from typing import Dict, List
from openai import OpenAI
from dotenv import load_dotenv


class SimplePoemGenerator:
    """간단한 시 생성기"""

    def __init__(self, api_key: str = None):
        """
        시 생성기 초기화

        Args:
            api_key: OpenAI API 키 (None이면 환경변수에서 로드)
        """
        # 환경변수 로드
        load_dotenv()
        
        # API 키 설정
        if api_key is None:
            api_key = os.getenv('OPENAI_API_KEY')

        if not api_key:
            raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다.")

        # 모델 설정 (환경변수에서 로드, 없으면 기본값)
        model = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')

        self.client = OpenAI(api_key=api_key)
        self.model = model

        # 시스템 프롬프트
        self.system_prompt = (
            "당신은 한국 문학에 정통한 시인입니다. "
            "주어진 조건에 맞춰 감동적이고 아름다운 한국어 시를 4편 작성합니다. "
            "각 시는 독창적이고 서로 다른 관점과 표현을 사용해야 합니다."
        )

    def generate_poems(self, style: str, author_style: str, keywords: List[str], length: str) -> Dict:
        """
        시 생성 메인 메서드

        Args:
            style: 시의 성향 (예: "낭만적인", "우울한")
            author_style: 작가 스타일 (예: "김소월", "윤동주")
            keywords: 포함할 단어 리스트
            length: 시의 길이 (예: "8행", "16행")

        Returns:
            4편의 시가 담긴 JSON 구조
        """
        try:
            # 사용자 프롬프트 생성
            user_prompt = self._create_user_prompt(style, author_style, keywords, length)

            # OpenAI API 호출
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.9,  # 창의성을 위해 높은 temperature
                max_tokens=2000
            )

            # 응답 파싱
            content = response.choices[0].message.content
            return self._parse_response(content, style, author_style, keywords, length)

        except Exception as e:
            print(f"❌ 시 생성 실패: {e}")
            return {
                "success": False,
                "error": str(e),
                "request": {
                    "style": style,
                    "author_style": author_style,
                    "keywords": keywords,
                    "length": length
                },
                "poems": []
            }

    def _create_user_prompt(self, style: str, author_style: str, keywords: List[str], length: str) -> str:
        """사용자 프롬프트 생성"""
        keywords_str = "', '".join(keywords)
        
        prompt = f"""다음 조건에 맞춰 4편의 시를 작성해주세요.

조건:
• 성향: {style}
• 작가 스타일: {author_style}
• 포함 단어: '{keywords_str}'
• 길이: {length}

요구사항:
• 각 시는 제목을 포함하여 작성하세요
• 시의 길이는 제목을 제외한 시의 내용의 길이입니다.
• 지정된 단어들을 자연스럽게 녹여내세요
• 은유와 상징을 적절히 활용하세요
• 감정과 정서가 잘 전달되도록 작성하세요
• 리듬감과 운율을 고려하세요
• 4편의 시는 서로 다른 관점과 표현을 사용하세요

최종 출력은 아래 JSON 형식을 그대로 지켜 주세요:
{{
  "poem1": "첫 번째 시",
  "poem2": "두 번째 시",
  "poem3": "세 번째 시",
  "poem4": "네 번째 시"
}}"""
        
        return prompt

    def _parse_response(self, content: str, style: str, author_style: str, keywords: List[str], length: str) -> Dict:
        """OpenAI 응답 파싱"""
        try:
            # JSON 코드 블록 제거
            content = content.replace('```json', '').replace('```', '').strip()
            
            # 일반적인 JSON 파싱 시도
            parsed = json.loads(content)
            
            return {
                "success": True,
                "request": {
                    "style": style,
                    "author_style": author_style,
                    "keywords": keywords,
                    "length": length
                },
                "poems": [
                    parsed.get("poem1", ""),
                    parsed.get("poem2", ""),
                    parsed.get("poem3", ""),
                    parsed.get("poem4", "")
                ]
            }

        except json.JSONDecodeError as e:
            print(f"⚠️ JSON 파싱 실패: {e}")
            print(f"원본 응답: {content}")
            
            # 여러 가지 JSON 수정 방법 시도
            cleaned_content = self._clean_malformed_json(content)
            try:
                parsed = json.loads(cleaned_content)
                print("✅ JSON 정리 후 파싱 성공")
                return {
                    "success": True,
                    "request": {
                        "style": style,
                        "author_style": author_style,
                        "keywords": keywords,
                        "length": length
                    },
                    "poems": [
                        parsed.get("poem1", ""),
                        parsed.get("poem2", ""),
                        parsed.get("poem3", ""),
                        parsed.get("poem4", "")
                    ]
                }
            except json.JSONDecodeError:
                print("⚠️ JSON 정리 후에도 파싱 실패, 대안 파싱 사용")
                
            # JSON 파싱 실패 시 텍스트를 4등분하여 반환
            return self._fallback_parse(content, style, author_style, keywords, length)

    def _clean_malformed_json(self, content: str) -> str:
        """JSON 파싱 오류를 수정하기 위한 정리 메서드"""
        try:
            # 1. 기본적인 정리
            cleaned = content.strip()
            
            # 2. 코드 블록 제거 (```json, ``` 등)
            cleaned = cleaned.replace('```json', '').replace('```', '').strip()
            
            # 3. 후행 쉼표 제거 (객체 끝의 쉼표)
            import re
            # "field": "value", } 형태의 후행 쉼표 제거
            cleaned = re.sub(r',(\s*[}\]])', r'\1', cleaned)
            
            # 4. 개행 문자와 불필요한 공백 정리
            # JSON 문자열 내부의 개행은 보존하되, 구조적 공백만 정리
            lines = cleaned.split('\n')
            cleaned_lines = []
            in_string = False
            for line in lines:
                if not in_string:
                    # JSON 구조 부분은 불필요한 공백 제거
                    line = line.strip()
                    if line:
                        cleaned_lines.append(line)
                else:
                    # 문자열 내부는 원본 유지
                    cleaned_lines.append(line)
                
                # 문자열 상태 추적 (간단한 버전)
                quote_count = line.count('"') - line.count('\\"')
                if quote_count % 2 == 1:
                    in_string = not in_string
            
            cleaned = '\n'.join(cleaned_lines)
            
            # 5. 중복 쉼표 제거
            cleaned = re.sub(r',+', ',', cleaned)
            
            # 6. 객체 사이의 불필요한 쉼표 제거
            # }{ 패턴을 },{ 로 수정하지 않고 그대로 두기 (이미 올바른 형태일 수 있음)
            
            # 7. 기본적인 JSON 구조 검증
            if not (cleaned.startswith('{') and cleaned.endswith('}')):
                # JSON 객체가 아닌 경우 감싸기
                if 'poem1' in cleaned and not cleaned.startswith('{'):
                    cleaned = '{' + cleaned + '}'
            
            return cleaned
            
        except Exception as e:
            print(f"⚠️ JSON 정리 과정에서 오류 발생: {e}")
            # 정리 실패 시 원본 반환
            return content

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


def test_poem_generator():
    """시 생성기 테스트 함수"""
    print("🧪 간단한 시 생성기 테스트 시작\n")
    
    # pt_prompt_gpt.json 데이터 로드
    json_file_path = "input/pt_prompt_gpt.json"
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            test_data = json.load(f)
    except FileNotFoundError:
        print(f"❌ 테스트 데이터 파일을 찾을 수 없습니다: {json_file_path}")
        # 대안 테스트 데이터
        test_data = [
            {
                "성향": "낭만적인",
                "작가스타일": "김소월",
                "포함단어": ["꽃", "바람", "향기"],
                "길이": "8행"
            }
        ]

    try:
        # 시 생성기 초기화
        generator = SimplePoemGenerator()

        # 첫 번째 테스트 케이스 사용
        test_case = test_data[0]
        print(f"📋 테스트 케이스: {test_case['성향']} 성향, {test_case['작가스타일']} 스타일")
        
        # 시 생성
        result = generator.generate_poems(
            style=test_case["성향"],
            author_style=test_case["작가스타일"],
            keywords=test_case["포함단어"],
            length=test_case["길이"]
        )

        # 결과 출력
        generator.display_poems(result)

        # JSON 결과도 출력
        print("\n" + "=" * 60)
        print("📊 JSON 결과")
        print("=" * 60)
        print(json.dumps(result, ensure_ascii=False, indent=2))

    except Exception as e:
        print(f"❌ 테스트 실패: {e}")


if __name__ == "__main__":
    test_poem_generator()