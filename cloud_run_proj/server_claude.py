#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FastAPI server that exposes:
1) GET /ping                      -> health check
2) POST /chat                     -> non-streaming LLM response
3) POST /chat/stream              -> streaming LLM response (SSE via StreamingResponse)

This sample uses the Anthropics Python SDK and mirrors the streaming pattern
from your 05_Streaming.ipynb (client.messages.create(..., stream=True)).

Setup
-----
pip install -U fastapi "uvicorn[standard]" anthropic python-dotenv pydantic
export ANTHROPIC_API_KEY="sk-ant-..."
# (optional) put it in a .env file and it will be loaded automatically.

Run
---
uvicorn server:app --host 0.0.0.0 --port 8000 --reload

Test
----
See client.py for simple tests (non-stream + stream).
"""

from __future__ import annotations

import json

from typing import Optional, Dict, Any, Generator

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field
from anthropic import Anthropic
from dotenv import load_dotenv

# Load .env (if present) to pick up ANTHROPIC_API_KEY
load_dotenv()

# Create FastAPI app
app = FastAPI(title="Anthropic Streaming Demo (FastAPI)")


# Create Anthropics client. Will automatically use ANTHROPIC_API_KEY env var.
def get_anthropic_client() -> Anthropic:
    try:
        return Anthropic()
    except Exception as e:
        raise RuntimeError(f"Failed to initialize Anthropic client: {e}")


class ChatRequest(BaseModel):
    prompt: str = Field(..., description="The user's prompt")
    model: str = Field("claude-3-haiku-20240307", description="Anthropic model name")
    max_tokens: int = Field(512, ge=1, le=8192, description="Max tokens to generate")
    temperature: float = Field(0.0, ge=0.0, le=1.0, description="Sampling temperature")
    system: Optional[str] = Field(None, description="Optional system prompt")


@app.get("/ping")
def ping() -> Dict[str, str]:
    """
    Health check endpoint.
    """
    return {"message": "pong"}


@app.post("/chat")
def chat(req: ChatRequest) -> JSONResponse:
    """
    Non-streaming: returns the full model response in one JSON payload.
    """
    client = get_anthropic_client()

    try:
        messages = [{"role": "user", "content": req.prompt}]
        kwargs: Dict[str, Any] = dict(
            model=req.model,
            messages=messages,
            max_tokens=req.max_tokens,
            temperature=req.temperature,
        )
        if req.system:
            kwargs["system"] = req.system

        resp = client.messages.create(**kwargs)  # stream=False by default

        # The text content is typically in resp.content[0].text for text outputs
        text_out = ""
        for block in getattr(resp, "content", []) or []:
            if getattr(block, "type", None) == "text":
                text_out += getattr(block, "text", "")

        payload = {
            "model": req.model,
            "content": text_out,
            "raw": resp.to_dict() if hasattr(resp, "to_dict") else resp.__dict__,
        }
        return JSONResponse(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _sse_format(data: Dict[str, Any]) -> bytes:
    """
    Helper to format a dict as a Server-Sent Event (SSE) data frame.
    """
    return f"data: {json.dumps(data, ensure_ascii=False)}\n\n".encode("utf-8")


@app.post("/chat/stream")
def chat_stream(req: ChatRequest) -> StreamingResponse:
    """
    Streaming: yields tokens as SSE frames (text/event-stream).
    Clients should read line-by-line for 'data: ...' payloads.
    """
    client = get_anthropic_client()

    def event_generator() -> Generator[bytes, None, None]:
        try:
            messages = [{"role": "user", "content": req.prompt}]
            kwargs: Dict[str, Any] = dict(
                model=req.model,
                messages=messages,
                max_tokens=req.max_tokens,
                temperature=req.temperature,
                # IMPORTANT: stream=True so we get event iterator
                # stream=True,
            )
            if req.system:
                kwargs["system"] = req.system

            # Using the context manager ensures the HTTP connection closes cleanly.
            with client.messages.stream(**kwargs) as stream:
                yield _sse_format({"type": "start"})
                for event in stream:
                    # We only forward deltas that carry text for simple demos.
                    if event.type == "content_block_delta":
                        # event.delta.text is the incremental token text
                        text = getattr(event.delta, "text", "")
                        if text:
                            yield _sse_format({"type": "delta", "text": text})
                    elif event.type == "message_stop":
                        # Final bookkeeping if needed
                        pass
                # Signal the end of the stream
                yield _sse_format({"type": "done"})
        except Exception as e:
            # Send an error frame to the client
            yield _sse_format({"type": "error", "error": str(e)})

    headers = {
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
        # Note: CORS headers can be added here if you need cross-origin access.
    }
    return StreamingResponse(event_generator(), headers=headers, media_type="text/event-stream; charset=utf-8")
