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
import logging
import uuid
from datetime import datetime, timezone
from typing import Any

logger = logging.getLogger(__name__)

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

_MANNEQUIN_PROMPT = (
    "A professional fashion photo of a mannequin wearing the exact outfit shown in the "
    "reference image. Clean white background, full body view, soft studio lighting. "
    "Fashion editorial style."
)

_PERSON_TRYON_PROMPT = (
    "Virtual try-on: Image 1 shows a person. Image 2 shows the clothing items to wear. "
    "Dress the person from Image 1 in ALL the individual clothing items shown in Image 2. "
    "CRITICAL RULES: "
    "1) Identify EACH separate garment piece (top, bottom, accessories, shoes, bags) — "
    "they are SEPARATE items, not a single piece. "
    "2) Reproduce EVERY item independently — if you see a shirt + shorts + bag, show ALL THREE as distinct pieces. "
    "3) DO NOT merge multiple garments into one — a shirt and shorts are TWO separate items, not a dress. "
    "4) Preserve exact garment structure for each piece — if sleeveless, keep sleeveless; "
    "if short sleeves, keep short; maintain exact cut, length, and details. "
    "5) Keep all colors, patterns, and textures identical to reference for each individual piece. "
    "6) If garments are layered, show each layer distinctly. "
    "7) Preserve person's face, body, pose, and background unchanged. "
    "Photorealistic, accurate multi-piece outfit reproduction required."
)

_MANNEQUIN_TRYON_PROMPT = (
    "Virtual try-on: Image 1 shows a mannequin. Image 2 shows the clothing items to wear. "
    "Dress the mannequin from Image 1 in ALL the individual clothing items shown in Image 2. "
    "CRITICAL RULES: "
    "1) Identify EACH separate garment piece (top, bottom, accessories) — "
    "they are SEPARATE items, not a single piece. "
    "2) Reproduce EVERY item independently — if you see a shirt + shorts + bag, show ALL THREE as distinct pieces. "
    "3) DO NOT merge multiple garments into one. "
    "4) Preserve exact garment structure for each piece — if sleeveless, keep sleeveless; "
    "if short sleeves, keep short; maintain exact cut, length, and details. "
    "5) Keep all colors, patterns, and textures identical to reference for each individual piece. "
    "6) If garments are layered, show each layer distinctly. "
    "7) Preserve mannequin's pose and clean background unchanged. "
    "Photorealistic, accurate multi-piece outfit reproduction required."
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
        logger.info("[suggest] START user=%s mood=%s", request.user_id, request.mood)

        wardrobe = await self._fetch_wardrobe(request.user_id)
        logger.info("[suggest] wardrobe items fetched: %d", len(wardrobe))
        if not wardrobe:
            logger.warning("[suggest] wardrobe empty — returning no results")
            return SuggestionResponse()

        combinations = await self._select_combinations(wardrobe, request.mood)
        logger.info("[suggest] combinations selected: %d", len(combinations))
        batch_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc).isoformat()
        logger.info("[suggest] batch_id=%s created_at=%s", batch_id, created_at)

        # Write a pending history entry immediately so the history log shows
        # this generation is in progress.
        await self._write_history_batch(
            request.user_id, batch_id, request.mood, [], created_at, status="pending"
        )

        outfit_ids: list[str] = []
        for idx, combo in enumerate(combinations):
            logger.info("[suggest] processing combo %d/%d items=%s", idx + 1, len(combinations), combo.item_ids)
            image_bytes = await self._build_outfit_image(wardrobe, combo.item_ids)
            logger.info("[suggest] outfit image built: %d bytes", len(image_bytes))
            mannequin_bytes = await self._generate_mannequin(image_bytes, request.user_id)
            logger.info("[suggest] mannequin image generated: %d bytes", len(mannequin_bytes))
            outfit_id = f"{batch_id}_{idx}"
            await self._upload_and_save(
                request.user_id, batch_id, idx, combo, mannequin_bytes, request.mood, created_at
            )
            outfit_ids.append(outfit_id)
            logger.info("[suggest] outfit %s saved", outfit_id)

        await self._write_history_batch(
            request.user_id, batch_id, request.mood, outfit_ids, created_at, status="complete"
        )
        logger.info("[suggest] DONE batch_id=%s outfit_ids=%s", batch_id, outfit_ids)

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
        """Build a vertical composite of outfit item images (or colored placeholders)."""
        id_to_item = {w["id"]: w for w in wardrobe}
        thumbnails: list[Image.Image] = []

        async with httpx.AsyncClient(timeout=30) as client:
            for iid in item_ids:
                item = id_to_item.get(iid)
                if not item:
                    continue

                image_url = item.get("photoUrl")
                if image_url:
                    r = await client.get(image_url)
                    if r.is_success:
                        try:
                            img = Image.open(io.BytesIO(r.content)).convert("RGB")
                            img.thumbnail(_THUMB_SIZE)
                            thumbnails.append(img)
                            continue
                        except Exception:
                            pass

                # Fallback: colored placeholder tile with item type label
                thumbnails.append(self._make_placeholder(item))

        if not thumbnails:
            thumbnails.append(Image.new("RGB", _THUMB_SIZE, (250, 245, 241)))

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

    @staticmethod
    def _make_placeholder(item: dict[str, Any]) -> Image.Image:
        """Create a solid-color tile with the item type as a label."""
        from PIL import ImageDraw, ImageFont

        color_hex = item.get("colorHex", "#C9788A")
        item_type = item.get("type", "item").capitalize()

        # Parse hex color, fall back to mauve
        try:
            hex_clean = color_hex.lstrip("#")
            r, g, b = int(hex_clean[0:2], 16), int(hex_clean[2:4], 16), int(hex_clean[4:6], 16)
            bg_color = (r, g, b)
        except Exception:
            bg_color = (201, 120, 138)  # mauve

        img = Image.new("RGB", _THUMB_SIZE, bg_color)
        draw = ImageDraw.Draw(img)

        # Text color: white on dark, dark on light
        luminance = 0.299 * bg_color[0] + 0.587 * bg_color[1] + 0.114 * bg_color[2]
        text_color = (255, 255, 255) if luminance < 140 else (45, 45, 45)

        try:
            font = ImageFont.load_default(size=24)
        except TypeError:
            font = ImageFont.load_default()

        bbox = draw.textbbox((0, 0), item_type, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        x = (_THUMB_SIZE[0] - text_w) // 2
        y = (_THUMB_SIZE[1] - text_h) // 2
        draw.text((x, y), item_type, fill=text_color, font=font)
        return img

    async def _generate_mannequin(self, composite_bytes: bytes, user_id: str) -> bytes:
        """Generate a styled mannequin or virtual try-on image.

        Image 1 (input_image)  → person photo or mannequin silhouette
        Image 2 (input_image_2) → clothing composite built from wardrobe items

        Falls back to a single-image generic prompt when no reference is available.
        """
        if self._use_firebase:
            profile = await self._fetch_user_profile(user_id)
            profile_photo_url = profile.get("profilePhotoUrl")
            body_type = profile.get("bodyType")

            if profile_photo_url:
                person_bytes = await self._download_url_bytes(profile_photo_url)
                if person_bytes:
                    logger.info("[suggest] virtual try-on with person photo, user=%s", user_id)
                    return await self._image_gen.generate(
                        _PERSON_TRYON_PROMPT,
                        input_image=person_bytes,
                        input_image_2=composite_bytes,
                    )

            if body_type:
                mannequin_bytes = await self._download_storage_bytes(f"mannequins/{body_type}.png")
                if mannequin_bytes:
                    logger.info("[suggest] virtual try-on with mannequin body_type=%s user=%s", body_type, user_id)
                    return await self._image_gen.generate(
                        _MANNEQUIN_TRYON_PROMPT,
                        input_image=mannequin_bytes,
                        input_image_2=composite_bytes,
                    )

        # Fallback: clothing composite only with generic fashion prompt
        logger.info("[suggest] fallback: generic prompt, no reference person")
        return await self._image_gen.generate(_MANNEQUIN_PROMPT, input_image=composite_bytes)

    async def _fetch_user_profile(self, user_id: str) -> dict[str, Any]:
        """Fetch user profile fields from Firestore."""
        try:
            db = firestore.client()
            doc = db.collection("users").document(user_id).get()
            return doc.to_dict() or {}
        except Exception as e:
            logger.warning("[suggest] _fetch_user_profile error: %s", e)
            return {}

    async def _download_url_bytes(self, url: str) -> bytes | None:
        """Download image bytes from an HTTP/HTTPS URL."""
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                r = await client.get(url)
                r.raise_for_status()
                return r.content
        except Exception as e:
            logger.warning("[suggest] _download_url_bytes failed url=%s error=%s", url, e)
            return None

    async def _download_storage_bytes(self, blob_path: str) -> bytes | None:
        """Download image bytes — tries local assets first, then Firebase Storage."""
        import os
        local_path = os.path.join(
            os.path.dirname(__file__), "..", "assets", blob_path
        )
        local_path = os.path.normpath(local_path)
        if os.path.exists(local_path):
            try:
                with open(local_path, "rb") as f:
                    logger.info("[suggest] loaded mannequin from local assets: %s", local_path)
                    return f.read()
            except Exception as e:
                logger.warning("[suggest] local asset read failed %s: %s", local_path, e)

        try:
            bucket = storage.bucket()
            blob = bucket.blob(blob_path)
            return blob.download_as_bytes()
        except Exception as e:
            logger.warning("[suggest] _download_storage_bytes failed path=%s error=%s", blob_path, e)
            return None

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
        status: str = "complete",
    ) -> None:
        """Write (or overwrite) the history/batch document — used as a generation log."""
        if not self._use_firebase:
            logger.debug("[suggest] _write_history_batch skipped (use_firebase=False)")
            return

        logger.info(
            "[suggest] writing history doc users/%s/history/%s status=%s outfit_ids=%s",
            user_id, batch_id, status, outfit_ids,
        )
        db = firestore.client()
        batch_doc = {
            "mood": mood,
            "status": status,
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
        logger.info("[suggest] history doc written OK (status=%s)", status)
