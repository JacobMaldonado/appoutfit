"""Gemini 2.5 Flash Lite LLM provider implementation."""

import json
from typing import TypeVar

import google.generativeai as genai
from pydantic import BaseModel

from app.providers.llm.base import LLMProvider

T = TypeVar("T", bound=BaseModel)

_MODEL_NAME = "gemini-2.5-flash-lite-preview-06-17"
_VISION_MODEL = "gemini-2.5-flash-lite-preview-06-17"


class GeminiProvider(LLMProvider):
    def __init__(self, api_key: str) -> None:
        genai.configure(api_key=api_key)
        self._text_model = genai.GenerativeModel(_MODEL_NAME)
        self._vision_model = genai.GenerativeModel(_VISION_MODEL)

    async def complete_structured(self, prompt: str, schema: type[T]) -> T:
        schema_json = json.dumps(schema.model_json_schema(), indent=2)
        full_prompt = (
            f"{prompt}\n\n"
            f"Respond with valid JSON that matches this schema:\n```json\n{schema_json}\n```\n"
            "Return only the JSON object, no markdown fences."
        )
        response = await self._text_model.generate_content_async(full_prompt)
        raw = response.text.strip().removeprefix("```json").removesuffix("```").strip()
        return schema.model_validate_json(raw)

    async def describe_image(self, image_bytes: bytes, prompt: str) -> str:
        import google.generativeai as genai_types

        image_part = {"mime_type": "image/jpeg", "data": image_bytes}
        response = await self._vision_model.generate_content_async([prompt, image_part])
        return response.text.strip()
