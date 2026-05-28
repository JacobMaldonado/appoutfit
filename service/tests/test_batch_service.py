"""Tests for BatchService."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.providers.image_gen.mock import MockImageGenProvider
from app.providers.llm.mock import MockLLMProvider
from app.schemas.suggestion import SuggestionResponse
from app.services.batch_service import BatchService, _MOODS
from app.services.suggestion_service import SuggestionService


@pytest.fixture
def suggestion_service() -> SuggestionService:
    return SuggestionService(MockLLMProvider(), MockImageGenProvider())


@pytest.fixture
def batch_service(suggestion_service: SuggestionService) -> BatchService:
    return BatchService(suggestion_service)


def _make_user_doc(uid: str) -> MagicMock:
    doc = MagicMock()
    doc.id = uid
    return doc


@pytest.mark.asyncio
async def test_run_processes_all_users(batch_service: BatchService) -> None:
    user_docs = [_make_user_doc("user1"), _make_user_doc("user2")]

    with (
        patch("app.services.batch_service.firestore") as mock_fs,
        patch.object(
            batch_service._suggestion,
            "generate",
            new=AsyncMock(return_value=SuggestionResponse(combinations=[], batch_id="b1")),
        ),
    ):
        mock_fs.client.return_value.collection.return_value.stream.return_value = user_docs
        result = await batch_service.run()

    assert result.processed_users == 2
    assert result.total_batches == 2 * len(_MOODS)


@pytest.mark.asyncio
async def test_run_continues_on_single_user_failure(batch_service: BatchService) -> None:
    user_docs = [_make_user_doc("user1"), _make_user_doc("user2")]
    call_count = 0

    async def flaky_generate(req):  # noqa: ANN001
        nonlocal call_count
        call_count += 1
        if req.user_id == "user1":
            raise RuntimeError("Simulated failure")
        return SuggestionResponse(combinations=[], batch_id="b1")

    with (
        patch("app.services.batch_service.firestore") as mock_fs,
        patch.object(batch_service._suggestion, "generate", side_effect=flaky_generate),
    ):
        mock_fs.client.return_value.collection.return_value.stream.return_value = user_docs
        result = await batch_service.run()

    # Both users processed even though user1 failed on all moods
    assert result.processed_users == 2
    assert call_count == 2 * len(_MOODS)


@pytest.mark.asyncio
async def test_run_no_users_returns_zeros(batch_service: BatchService) -> None:
    with patch("app.services.batch_service.firestore") as mock_fs:
        mock_fs.client.return_value.collection.return_value.stream.return_value = []
        result = await batch_service.run()

    assert result.processed_users == 0
    assert result.total_batches == 0
