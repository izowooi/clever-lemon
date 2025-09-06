from __future__ import annotations
import os
import time
import jwt
import httpx
import jwt
from jwt import PyJWKClient

SUPABASE_URL = "https://tnihnfuwhhtvbkmhwiut.supabase.co"
JWKS_URL = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json"
EXPECTED_ISS = f"{SUPABASE_URL}/auth/v1"

# 선택: JWKS 캐시 (Supabase Edge가 10분 캐시하므로 과도 캐시는 금물)
_JWKS_CACHE: dict | None = None
_JWKS_TS = 0

from jwt import algorithms as jwt_algorithms

def public_key_from_jwk(jwk: dict, fallback_alg: str | None = None):
   alg = jwk.get("alg") or fallback_alg or "ES256"
   if alg.startswith("RS"):
       return jwt_algorithms.RSAAlgorithm.from_jwk(jwk)
   if alg.startswith("ES"):
       return jwt_algorithms.ECAlgorithm.from_jwk(jwk)   # ← ES256 여기서 처리
   if alg == "EdDSA":
       return jwt_algorithms.ED25519Algorithm.from_jwk(jwk)
   raise ValueError(f"Unsupported alg: {alg}")

def _get_jwk_key_for(token: str):
   global _JWKS_CACHE, _JWKS_TS
   header = jwt.get_unverified_header(token)
   kid = header.get("kid")
   now = time.time()
   # 10분 이하로만 캐시(회전 시 안전)
   if not _JWKS_CACHE or now - _JWKS_TS > 600:
       _JWKS_CACHE = httpx.get(JWKS_URL, timeout=10).json()
       _JWKS_TS = now
   # kid 매칭되는 키 탐색
   for k in _JWKS_CACHE.get("keys", []):
       if k.get("kid") == kid:
           key = public_key_from_jwk(k, fallback_alg=header.get("alg"))
           return key
           # 혹시 회전 직후면 한 번 더 새로고침
   _JWKS_CACHE = httpx.get(JWKS_URL, timeout=10).json()
   _JWKS_TS = now
   for k in _JWKS_CACHE.get("keys", []):
       if k.get("kid") == kid:
           key = public_key_from_jwk(k, fallback_alg=header.get("alg"))
           return key
   raise ValueError("Signing key not found for kid")


def verify_and_decode_supabase_jwt(token: str) -> dict:
   key = _get_jwk_key_for(token)
   # aud는 Supabase 토큰에서 고정 의미가 약해 종종 검증 생략; iss/exp는 반드시 체크
   jwks_client = PyJWKClient(JWKS_URL, cache_keys=True)
   signing_key = jwks_client.get_signing_key_from_jwt(token)
   claims = jwt.decode(
       token,
       key=signing_key.key,
       algorithms=["ES256", "RS256", "EdDSA"],
       options={"require": ["exp", "iss", "sub"]},
       audience="authenticated",
   )
   if claims.get("iss") != EXPECTED_ISS:
       raise jwt.InvalidIssuerError(f"Unexpected iss: {claims.get('iss')}")
   return claims

# 사용 예시
if __name__ == "__main__":
   token = "eyJhbGciOiJFUzI1NiIsImtpZCI6IjNiMGJhNTkyLWM5NDQtNGMzNS05OGFlLTBjNmQ5ZmNmZDJkMCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3RuaWhuZnV3aGh0dmJrbWh3aXV0LnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiIwMWY4NDlkYy1jMjM1LTQ4YTMtODQ0Zi01YTk5NDkxNGIxNTgiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzU3MTMwODk4LCJpYXQiOjE3NTcxMjcyOTgsImVtYWlsIjoiaXpvd29vaTg1QGdtYWlsLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZ29vZ2xlIiwicHJvdmlkZXJzIjpbImdvb2dsZSJdfSwidXNlcl9tZXRhZGF0YSI6eyJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSUx5c1ZWMzVrY01tMkNfVHhfVDIxUUk2a3l5cEs4NEM0Qkt0eERDdzRKcHhlMEhRVFFvUT1zOTYtYyIsImVtYWlsIjoiaXpvd29vaTg1QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJmdWxsX25hbWUiOiJKb25nV29vIFBhcmsiLCJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJuYW1lIjoiSm9uZ1dvbyBQYXJrIiwicGhvbmVfdmVyaWZpZWQiOmZhbHNlLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSUx5c1ZWMzVrY01tMkNfVHhfVDIxUUk2a3l5cEs4NEM0Qkt0eERDdzRKcHhlMEhRVFFvUT1zOTYtYyIsInByb3ZpZGVyX2lkIjoiMTAzMTg1Mjc3ODkzMjQ4NzgxMjY2Iiwic3ViIjoiMTAzMTg1Mjc3ODkzMjQ4NzgxMjY2In0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoib2F1dGgiLCJ0aW1lc3RhbXAiOjE3NTcxMjcyOTh9XSwic2Vzc2lvbl9pZCI6Ijg1MzU2M2NjLTYyMjktNGUxZC05ZWI1LWRhMjBjNDYyMWE1ZCIsImlzX2Fub255bW91cyI6ZmFsc2V9.3AKUt0LSVhCRgss1Edij7OLoI70Wb5Ogg3K-FmR8KnVNhtxgYdsHj8hK51hBVbCyDsWk0PXt9E83SAPjysj2Sg"
   claims = verify_and_decode_supabase_jwt(token)
   print("sub (user id):", claims["sub"])
   print("role:", claims.get("role"))
   print("email:", claims.get("email"))
   print("exp:", claims["exp"])