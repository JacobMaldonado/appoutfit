"""Abstract base for all image generation providers."""

from abc import ABC, abstractmethod


class ImageGenProvider(ABC):
    @abstractmethod
    async def generate(self, prompt: str) -> bytes:
        """Generate an image from *prompt* and return raw PNG/JPEG bytes."""
