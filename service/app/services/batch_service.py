"""Batch suggestion service.

Iterates every user in the 'users' Firestore collection and generates
suggestions for all five moods. Designed to be triggered daily by
Cloud Scheduler.
"""

from __future__ import annotations

from firebase_admin import firestore

from app.schemas.suggestion import BatchSuggestionResponse, SuggestionRequest
from app.services.suggestion_service import SuggestionService

_MOODS = ["casual", "work", "brunch", "night", "active"]


class BatchService:
    def __init__(self, suggestion_service: SuggestionService, use_firebase: bool = True) -> None:
        self._suggestion = suggestion_service
        self._use_firebase = use_firebase

    async def run(self) -> BatchSuggestionResponse:
        if not self._use_firebase:
            return BatchSuggestionResponse(processed_users=0, total_batches=0)

        db = firestore.client()
        user_docs = list(db.collection("users").stream())

        processed = 0
        total_batches = 0

        for user_doc in user_docs:
            user_id = user_doc.id
            for mood in _MOODS:
                try:
                    result = await self._suggestion.generate(
                        SuggestionRequest(user_id=user_id, mood=mood)
                    )
                    if result.batch_id:
                        total_batches += 1
                except Exception:  # noqa: BLE001
                    # Log and continue — one user failure must not abort the whole batch
                    import logging
                    logging.getLogger(__name__).exception(
                        "Batch failed for user=%s mood=%s", user_id, mood
                    )
            processed += 1

        return BatchSuggestionResponse(
            processed_users=processed, total_batches=total_batches
        )
