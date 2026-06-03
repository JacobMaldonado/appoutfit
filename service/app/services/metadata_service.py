"""Metadata extraction service.

Receives a clothing image URL (already in Firebase Storage),
runs Gemini vision to extract structured metadata, and patches
the Firestore wardrobe document.
"""

from __future__ import annotations

import httpx
from firebase_admin import firestore

from app.providers.llm.base import LLMProvider
from app.schemas.clothing import ClothingMetadata
from app.schemas.suggestion import MetadataRequest, MetadataResponse

_METADATA_PROMPT = (
    "You are a fashion stylist AI. Analyse this clothing image and extract structured metadata. "
    "Be precise about the clothing type, which part of the body it covers, the dominant color as "
    "a hex string, the surface pattern, and write a concise style description."
)


class MetadataService:
    def __init__(self, llm: LLMProvider, use_firebase: bool = True) -> None:
        self._llm = llm
        self._use_firebase = use_firebase

    async def extract_and_save(self, request: MetadataRequest) -> MetadataResponse:
        image_bytes = await self._fetch_image(request.image_url)
        raw_description = await self._llm.describe_image(image_bytes, _METADATA_PROMPT)
        structured_prompt = (
            f"Based on this clothing description, fill in the metadata schema:\n{raw_description}"
        )
        metadata = await self._llm.complete_structured(structured_prompt, ClothingMetadata)
        await self._patch_firestore(request.user_id, request.item_id, metadata)
        return MetadataResponse(item_id=request.item_id, metadata=metadata)

    async def _fetch_image(self, url: str) -> bytes:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url)
            r.raise_for_status()
            return r.content

    async def _patch_firestore(
        self, user_id: str, item_id: str, metadata: ClothingMetadata
    ) -> None:
        if not self._use_firebase:
            return  # No-op in local env

        db = firestore.client()
        doc_ref = db.collection("users").document(user_id).collection("wardrobe").document(item_id)
        doc_ref.update(
            {
                "type": metadata.clothing_type.value,
                "coverage": metadata.coverage.value,
                "colorHex": metadata.color,
                "pattern": metadata.pattern.value,
                "shortDescription": metadata.short_description,
                "status": "ready",
            }
        )
