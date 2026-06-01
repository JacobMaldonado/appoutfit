"""Abstract base for all image generation providers."""

from abc import ABC, abstractmethod


class ImageGenProvider(ABC):
    @abstractmethod
    async def generate(self, prompt: str, input_image: bytes | None = None) -> bytes:
        """Generate or edit an image.

        Args:
            prompt: Text prompt describing the desired output.
            input_image: Optional reference image bytes. When provided, the
                provider uses it as an editing reference (image-to-image mode).
        """
