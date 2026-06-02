"""Black Forest Labs Flux image generation provider.

Uses the BFL async API:
  POST https://api.bfl.ai/v1/flux-2-klein-4b   → returns { id, polling_url, ... }
  GET  <polling_url>                             → poll until status == "Ready"

Per BFL docs, the polling_url from the submit response MUST be used directly.
Constructing /v1/get_result?id=... is not supported on the global endpoint.

The endpoint supports up to 4 separate reference images via:
  input_image, input_image_2, input_image_3, input_image_4
Each accepts a base64-encoded data URI (data:image/jpeg;base64,...).
"""

import asyncio
import base64

import httpx

from app.providers.image_gen.base import ImageGenProvider

_SUBMIT_URL = "https://api.bfl.ai/v1/flux-2-klein-4b"
_POLL_INTERVAL = 2.0
_MAX_POLLS = 60


def _to_data_uri(image_bytes: bytes) -> str:
    b64 = base64.b64encode(image_bytes).decode("utf-8")
    return f"data:image/jpeg;base64,{b64}"


class BFLFluxProvider(ImageGenProvider):
    def __init__(self, api_key: str) -> None:
        self._api_key = api_key
        self._headers = {"x-key": api_key, "Content-Type": "application/json"}

    async def generate(
        self,
        prompt: str,
        input_image: bytes | None = None,
        input_image_2: bytes | None = None,
    ) -> bytes:
        async with httpx.AsyncClient(timeout=120) as client:
            polling_url = await self._submit(client, prompt, input_image, input_image_2)
            image_url = await self._poll(client, polling_url)
            response = await client.get(image_url)
            response.raise_for_status()
            return response.content

    async def _submit(
        self,
        client: httpx.AsyncClient,
        prompt: str,
        input_image: bytes | None,
        input_image_2: bytes | None,
    ) -> str:
        """Submit a generation task; returns the polling_url from the response."""
        payload: dict = {
            "prompt": prompt,
            "width": 512,
            "height": 768,
            "output_format": "jpeg",
        }
        if input_image is not None:
            payload["input_image"] = _to_data_uri(input_image)
        if input_image_2 is not None:
            payload["input_image_2"] = _to_data_uri(input_image_2)

        r = await client.post(_SUBMIT_URL, json=payload, headers=self._headers)
        r.raise_for_status()
        data = r.json()
        return data["polling_url"]

    async def _poll(self, client: httpx.AsyncClient, polling_url: str) -> str:
        """Poll the polling_url until the result is ready; returns the image URL."""
        for _ in range(_MAX_POLLS):
            r = await client.get(polling_url, headers=self._headers)
            r.raise_for_status()
            data = r.json()
            status = data.get("status")
            if status == "Ready":
                return data["result"]["sample"]
            if status in {"Error", "Failed"}:
                raise RuntimeError(f"BFL generation failed: {data}")
            await asyncio.sleep(_POLL_INTERVAL)
        raise TimeoutError("BFL generation timed out")

