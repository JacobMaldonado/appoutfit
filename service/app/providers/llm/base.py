"""Abstract base for all LLM providers."""

from abc import ABC, abstractmethod
from typing import TypeVar

from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


class LLMProvider(ABC):
    @abstractmethod
    async def complete_structured(self, prompt: str, schema: type[T]) -> T:
        """Return a structured Pydantic model parsed from an LLM completion."""

    @abstractmethod
    async def describe_image(self, image_bytes: bytes, prompt: str) -> str:
        """Return a text description of *image_bytes* guided by *prompt*."""
