"""Outfit suggestion service.

Pipeline:
1. Fetch wardrobe metadata from Firestore (≤100 items).
2. Gemini structured output → 4 OutfitCombination objects (item IDs + style note).
3. Download item images from Firebase Storage.
4. Concatenate images with Pillow into a single composite.
5. Gemini vision on composite → fashion illustration prompt.
6. BFL Flux text-to-image → mannequin PNG bytes.
7. Upload mannequin PNG to Firebase Storage.
8. Write SuggestionBatch to Firestore.
"""

from __future__ import annotations

import io
import uuid
from datetime import datetime, timezone
from typing import Any

import httpx
from firebase_admin import firestore, storage
from PIL import Image
from pydantic import BaseModel, Field

from app.providers.image_gen.base import ImageGenProvider
from app.providers.llm.base import LLMProvider
from app.schemas.suggestion import (
    OutfitCombination,
    SuggestionRequest,
    SuggestionResponse,
)

_MAX_WARDROBE_ITEMS = 100
_OUTFIT_COUNT = 4
_THUMB_SIZE = (200, 280)

_COMBO_PROMPT_TEMPLATE = (
    "You are a professional personal stylist. "
    "The user wants outfit suggestions for the '{mood}' dress code. "
    "Here are their wardrobe items (JSON array):\n{items_json}\n\n"
    "Select {count} distinct outfit combinations. Each outfit must use 2–4 items. "
    "Use only the item IDs provided. Return a JSON object with a 'combinations' key "
    "containing an array of objects with 'item_ids' (array of strings) and 'style_note' (string)."
)

_MANNEQUIN_VISION_PROMPT = (
    "Describe the style of this outfit in detail for a fashion illustration prompt. "
    "Focus on silhouette, fabrics, colours, and the overall aesthetic. "
    "Keep it under 200 words."
)

_MANNEQUIN_GEN_PREFIX = (
    "Fashion illustration, unanimated mannequin wearing: "
)


class _CombinationsWrapper(BaseModel):
    combinations: list[OutfitCombination] = Field(default_factory=list)


_STUB_WARDROBE = [
    {"id": "stub-shirt", "type": "shirt", "coverage": "top", "color": "#F9E8E8",
     "pattern": "solid", "imageUrl": None},
    {"id": "stub-jeans", "type": "jeans", "coverage": "bottom", "color": "#1A237E",
     "pattern": "solid", "imageUrl": None},
    {"id": "stub-jacket", "type": "jacket", "coverage": "layer", "color": "#2D2D2D",
     "pattern": "solid", "imageUrl": None},
    {"id": "stub-dress", "type": "dress", "coverage": "fullbody", "color": "#C9788A",
     "pattern": "floral", "imageUrl": None},
]


class SuggestionService:
    def __init__(
        self,
        llm: LLMProvider,
        image_gen: ImageGenProvider,
        use_firebase: bool = True,
    ) -> None:
        self._llm = llm
        self._image_gen = image_gen
        self._use_firebase = use_firebase

    async def generate(self, request: SuggestionRequest) -> SuggestionResponse:
        wardrobe = await self._fetch_wardrobe(request.user_id)
        if not wardrobe:
            return SuggestionResponse()

        combinations = await self._select_combinations(wardrobe, request.mood)
        batch_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc).isoformat()

        outfit_ids: list[str] = []
        for idx, combo in enumerate(combinations):
            image_bytes = await self._build_outfit_image(wardrobe, combo.item_ids)
            mannequin_bytes = await self._generate_mannequin(image_bytes)
            outfit_id = f"{batch_id}_{idx}"
            await self._upload_and_save(
                request.user_id, batch_id, idx, combo, mannequin_bytes, request.mood, created_at
            )
            outfit_ids.append(outfit_id)

        await self._write_history_batch(request.user_id, batch_id, request.mood, outfit_ids, created_at)

        return SuggestionResponse(combinations=combinations, batch_id=batch_id)

    async def _fetch_wardrobe(self, user_id: str) -> list[dict[str, Any]]:
        if not self._use_firebase:
            return _STUB_WARDROBE  # Return stub data in local env

        db = firestore.client()
        docs = (
            db.collection("users")
            .document(user_id)
            .collection("wardrobe")
            .limit(_MAX_WARDROBE_ITEMS)
            .stream()
        )
        items = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            items.append(data)
        return items

    async def _select_combinations(
        self, wardrobe: list[dict[str, Any]], mood: str
    ) -> list[OutfitCombination]:
        import json

        slim = [{"id": w["id"], "type": w.get("type"), "coverage": w.get("coverage"),
                 "color": w.get("color"), "pattern": w.get("pattern")} for w in wardrobe]
        prompt = _COMBO_PROMPT_TEMPLATE.format(
            mood=mood, items_json=json.dumps(slim, indent=2), count=_OUTFIT_COUNT
        )
        result = await self._llm.complete_structured(prompt, _CombinationsWrapper)
        return result.combinations[:_OUTFIT_COUNT]

    async def _build_outfit_image(
        self, wardrobe: list[dict[str, Any]], item_ids: list[str]
    ) -> bytes:
        id_to_item = {w["id"]: w for w in wardrobe}
        image_urls = [
            id_to_item[iid].get("imageUrl")
            for iid in item_ids
            if iid in id_to_item and id_to_item[iid].get("imageUrl")
        ]

        if not image_urls:
            # No images available — return blank composite placeholder
            canvas = Image.new("RGB", (_THUMB_SIZE[0], _THUMB_SIZE[1] * 2), (250, 245, 241))
            buf = io.BytesIO()
            canvas.save(buf, format="JPEG")
            return buf.getvalue()

        thumbnails: list[Image.Image] = []
        async with httpx.AsyncClient(timeout=30) as client:
            for url in image_urls:
                r = await client.get(url)
                if r.is_success:
                    img = Image.open(io.BytesIO(r.content)).convert("RGB")
                    img.thumbnail(_THUMB_SIZE)
                    thumbnails.append(img)

        if not thumbnails:
            canvas = Image.new("RGB", (_THUMB_SIZE[0], _THUMB_SIZE[1] * 2), (250, 245, 241))
            buf = io.BytesIO()
            canvas.save(buf, format="JPEG")
            return buf.getvalue()

        total_height = sum(t.height for t in thumbnails)
        max_width = max(t.width for t in thumbnails)
        composite = Image.new("RGB", (max_width, total_height), (250, 245, 241))
        y_offset = 0
        for thumb in thumbnails:
            composite.paste(thumb, (0, y_offset))
            y_offset += thumb.height

        buf = io.BytesIO()
        composite.save(buf, format="JPEG", quality=85)
        return buf.getvalue()

    async def _generate_mannequin(self, composite_bytes: bytes) -> bytes:
        style_description = await self._llm.describe_image(
            composite_bytes, _MANNEQUIN_VISION_PROMPT
        )
        gen_prompt = _MANNEQUIN_GEN_PREFIX + style_description
        return await self._image_gen.generate(gen_prompt)

    async def _upload_and_save(
        self,
        user_id: str,
        batch_id: str,
        idx: int,
        combo: OutfitCombination,
        image_bytes: bytes,
        mood: str,
        created_at: str,
    ) -> None:
        if not self._use_firebase:
            return  # No-op in local env

        bucket = storage.bucket()
        blob_path = f"users/{user_id}/suggestions/{batch_id}/{idx}.jpg"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(image_bytes, content_type="image/jpeg")
        blob.make_public()
        image_url = blob.public_url

        db = firestore.client()
        outfit_doc = {
            "batchId": batch_id,
            "mood": mood,
            "itemIds": combo.item_ids,
            "styleNote": combo.style_note,
            "imageUrl": image_url,
            "saved": False,
            "createdAt": created_at,
        }
        (
            db.collection("users")
            .document(user_id)
            .collection("outfits")
            .document(f"{batch_id}_{idx}")
            .set(outfit_doc)
        )

    async def _write_history_batch(
        self,
        user_id: str,
        batch_id: str,
        mood: str,
        outfit_ids: list[str],
        created_at: str,
    ) -> None:
        """Write the history/batch document the app watches to show results."""
        if not self._use_firebase:
            return

        db = firestore.client()
        batch_doc = {
            "mood": mood,
            "status": "complete",
            "outfitIds": outfit_ids,
            "createdAt": created_at,
        }
        (
            db.collection("users")
            .document(user_id)
            .collection("history")
            .document(batch_id)
            .set(batch_doc)
        )
