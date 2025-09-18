#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FastAPI server converted to use the OpenAI Python SDK.

Exposes:
1) GET /ping                      -> health check
2) POST /chat                     -> non-streaming LLM response (OpenAI)
3) POST /chat/stream              -> streaming LLM response via SSE (OpenAI)

Notes
-----
- Chat Completions API is used for most models (e.g., gpt-4o-mini).
- Responses API is used when the model name starts with "gpt-5" (non-streaming here is native;
  streaming is supported via Responses streaming events as best-effort).
- SSE frames are JSON objects prefixed with "data: " and a blank line terminator.

Setup
-----
uv add fastapi "uvicorn[standard]" openai python-dotenv pydantic httpx
export OPENAI_API_KEY="sk-..."
uv run uvicorn server_openai:app --host 0.0.0.0 --port 8000 --reload
"""

from __future__ import annotations

import json
import os
from typing import Optional, Dict, Any, Generator

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from openai import OpenAI

# Load env vars (OPENAI_API_KEY, etc.)
load_dotenv()

app = FastAPI(title="OpenAI Streaming Demo (FastAPI)")


def get_openai_client() -> OpenAI:
    try:
        # If OPENAI_API_KEY isn't set, OpenAI() will raise on first request.
        return OpenAI()
    except Exception as e:
        raise RuntimeError(f"Failed to initialize OpenAI client: {e}")


class ChatRequest(BaseModel):
    prompt: str = Field(..., description="The user's prompt")
    model: str = Field("gpt-4o-mini", description="OpenAI model name")
    max_tokens: int = Field(512, ge=1, le=8192, description="Max tokens to generate")
    temperature: float = Field(0.0, ge=0.0, le=1.0, description="Sampling temperature")
    system: Optional[str] = Field(None, description="Optional system prompt")


@app.get("/ping")
def ping() -> Dict[str, str]:
    return {"message": "pong"}


@app.post("/chat")
def chat(req: ChatRequest) -> JSONResponse:
    """
    Non-streaming: returns one JSON payload containing the full model response.
    - For gpt-5* models: use Responses API (instructions+input).
    - For others: use Chat Completions API (messages).
    """
    client = get_openai_client()

    try:
        # gpt-5* → Responses API
        if req.model.lower().startswith("gpt-5"):
            kwargs: Dict[str, Any] = {
                "model": req.model,
                # Following your poem_generator_modern mapping:
                # system-like → instructions, user content → input
                "instructions": req.system or "",
                "input": req.prompt,
            }
            # map max_tokens to Responses' max_output_tokens
            if req.max_tokens:
                kwargs["max_output_tokens"] = req.max_tokens
            # temperature is not always applicable to Responses; omit unless needed.

            resp = client.responses.create(**kwargs)
            # SDK offers a convenient aggregated text accessor
            text_out = getattr(resp, "output_text", None) or ""
            payload = {"model": req.model, "content": text_out}
            return JSONResponse(payload)

        # Other models → Chat Completions
        messages = []
        if req.system:
            messages.append({"role": "system", "content": req.system})
        messages.append({"role": "user", "content": req.prompt})

        kwargs_cc: Dict[str, Any] = dict(
            model=req.model,
            messages=messages,
            max_tokens=req.max_tokens,
            temperature=req.temperature,
        )
        resp_cc = client.chat.completions.create(**kwargs_cc)
        text_out = resp_cc.choices[0].message.content or ""
        payload = {"model": req.model, "content": text_out}
        return JSONResponse(payload)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _sse(bs: Dict[str, Any]) -> bytes:
    """Format a dict as a Server-Sent Event (SSE) frame."""
    return f"data: {json.dumps(bs, ensure_ascii=False)}\n\n".encode("utf-8")


@app.post("/chat/stream")
def chat_stream(req: ChatRequest) -> StreamingResponse:
    """
    Streaming via SSE frames.
    - For Chat Completions: native streaming with stream=True.
    - For Responses (gpt-5*): best-effort using Responses streaming events.
    """
    client = get_openai_client()

    def event_gen() -> Generator[bytes, None, None]:
        try:
            # gpt-5* → Responses streaming (best-effort)
            if req.model.lower().startswith("gpt-5"):
                kwargs: Dict[str, Any] = {
                    "model": req.model,
                    "instructions": req.system or "",
                    "input": req.prompt,
                }
                if req.max_tokens:
                    kwargs["max_output_tokens"] = req.max_tokens

                # Prefer the context-manager streaming API if available
                try:
                    with client.responses.stream(**kwargs) as stream:
                        yield _sse({"type": "start"})
                        for event in stream:
                            # We only forward textual deltas to keep the SSE simple.
                            # The OpenAI SDK emits typed events such as:
                            # "response.output_text.delta", "response.completed", etc.
                            etype = getattr(event, "type", "")
                            if etype.endswith("output_text.delta"):
                                delta = getattr(event, "delta", "")
                                if delta:
                                    yield _sse({"type": "delta", "text": delta})
                            elif etype.endswith("completed"):
                                # end-of-stream signal will be sent after loop
                                pass
                        yield _sse({"type": "done"})
                        return
                except AttributeError:
                    # Fallback: if .responses.stream is unavailable, do non-stream call
                    # and chunk the result so client-side can still test SSE.
                    resp = client.responses.create(**kwargs)
                    text_out = getattr(resp, "output_text", None) or ""
                    yield _sse({"type": "start"})
                    for i in range(0, len(text_out), 64):
                        yield _sse({"type": "delta", "text": text_out[i : i + 64]})
                    yield _sse({"type": "done"})
                    return

            # Other models → Chat Completions native streaming
            messages = []
            if req.system:
                messages.append({"role": "system", "content": req.system})
            messages.append({"role": "user", "content": req.prompt})

            kwargs_cc: Dict[str, Any] = dict(
                model=req.model,
                messages=messages,
                max_tokens=req.max_tokens,
                temperature=req.temperature,
                stream=True,
            )

            # Old-school generator streaming (widely compatible)
            yield _sse({"type": "start"})
            for chunk in client.chat.completions.create(**kwargs_cc):
                try:
                    delta = chunk.choices[0].delta.content
                except Exception:
                    delta = None
                if delta:
                    yield _sse({"type": "delta", "text": delta})
            yield _sse({"type": "done"})

        except Exception as e:
            yield _sse({"type": "error", "error": str(e)})

    headers = {
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
    }
    return StreamingResponse(event_gen(), headers=headers, media_type="text/event-stream; charset=utf-8")
