"""Black Forest Labs Flux image generation provider.

Uses the BFL async API:
  POST https://api.bfl.ai/v1/flux-kontext-pro  (or flux-pro-1.1, configurable)
  GET  https://api.bfl.ai/v1/get_result?id=...  (poll until ready)
"""

import asyncio

import httpx

from app.providers.image_gen.base import ImageGenProvider

_SUBMIT_URL = "https://api.bfl.ai/v1/flux-pro-1.1"
_RESULT_URL = "https://api.bfl.ai/v1/get_result"
_POLL_INTERVAL = 2.0
_MAX_POLLS = 60


class BFLFluxProvider(ImageGenProvider):
    def __init__(self, api_key: str) -> None:
        self._api_key = api_key
        self._headers = {"x-key": api_key, "Content-Type": "application/json"}

    async def generate(self, prompt: str) -> bytes:
        async with httpx.AsyncClient(timeout=120) as client:
            task_id = await self._submit(client, prompt)
            image_url = await self._poll(client, task_id)
            response = await client.get(image_url)
            response.raise_for_status()
            return response.content

    async def _submit(self, client: httpx.AsyncClient, prompt: str) -> str:
        payload = {
            "prompt": prompt,
            "width": 512,
            "height": 768,
            "output_format": "jpeg",
        }
        r = await client.post(_SUBMIT_URL, json=payload, headers=self._headers)
        r.raise_for_status()
        data = r.json()
        return data["id"]

    async def _poll(self, client: httpx.AsyncClient, task_id: str) -> str:
        for _ in range(_MAX_POLLS):
            r = await client.get(_RESULT_URL, params={"id": task_id}, headers=self._headers)
            r.raise_for_status()
            data = r.json()
            status = data.get("status")
            if status == "Ready":
                return data["result"]["sample"]
            if status in {"Error", "Failed"}:
                raise RuntimeError(f"BFL generation failed: {data}")
            await asyncio.sleep(_POLL_INTERVAL)
        raise TimeoutError("BFL generation timed out")
