"""Abstract base for all image generation providers."""

from abc import ABC, abstractmethod


class ImageGenProvider(ABC):
    @abstractmethod
    async def generate(
        self,
        prompt: str,
        input_image: bytes | None = None,
        input_image_2: bytes | None = None,
    ) -> bytes:
        """Generate or edit an image.

        Args:
            prompt: Text prompt describing the desired output.
            input_image: Optional first reference image bytes (e.g. person/mannequin).
            input_image_2: Optional second reference image bytes (e.g. outfit composite).
        """
