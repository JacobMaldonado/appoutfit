"""Mock image generation provider — returns a 1×1 white pixel PNG."""

import struct
import zlib

from app.providers.image_gen.base import ImageGenProvider

# Minimal valid 1×1 white PNG (precomputed bytes)
_WHITE_1PX_PNG = (
    b"\x89PNG\r\n\x1a\n"  # PNG signature
    + b"\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde"
    + b"\x00\x00\x00\x0cIDATx\x9cc\xf8\xff\xff?\x00\x05\xfe\x02\xfe\xdc\xccY\xe7"
    + b"\x00\x00\x00\x00IEND\xaeB`\x82"
)


class MockImageGenProvider(ImageGenProvider):
    async def generate(self, prompt: str, input_image: bytes | None = None) -> bytes:  # noqa: ARG002
        return _WHITE_1PX_PNG
