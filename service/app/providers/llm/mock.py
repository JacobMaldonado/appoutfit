"""Deterministic mock LLM provider for local env and tests."""

import json
from typing import TypeVar

from pydantic import BaseModel

from app.providers.llm.base import LLMProvider

T = TypeVar("T", bound=BaseModel)


class MockLLMProvider(LLMProvider):
    """Returns the *default* instance of the requested schema (all fields at defaults)."""

    async def complete_structured(self, prompt: str, schema: type[T]) -> T:
        # Build a minimal valid instance using schema field defaults / examples
        dummy: dict = {}
        for field_name, field_info in schema.model_fields.items():
            if field_info.default is not None and field_info.default is not ...:
                dummy[field_name] = field_info.default
            elif field_info.annotation and hasattr(field_info.annotation, "__origin__"):
                # list[...] → empty list
                dummy[field_name] = []
            else:
                dummy[field_name] = None
        return schema.model_validate(dummy)

    async def describe_image(self, image_bytes: bytes, prompt: str) -> str:
        return "A mock clothing item description for testing purposes."
