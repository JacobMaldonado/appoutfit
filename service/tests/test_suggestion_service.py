"""Tests for SuggestionService using mock providers."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.providers.image_gen.mock import MockImageGenProvider
from app.providers.llm.mock import MockLLMProvider
from app.schemas.suggestion import OutfitCombination, SuggestionRequest
from app.services.suggestion_service import SuggestionService, _CombinationsWrapper


@pytest.fixture
def mock_llm() -> MockLLMProvider:
    return MockLLMProvider()


@pytest.fixture
def mock_image_gen() -> MockImageGenProvider:
    return MockImageGenProvider()


@pytest.fixture
def service(mock_llm: MockLLMProvider, mock_image_gen: MockImageGenProvider) -> SuggestionService:
    return SuggestionService(mock_llm, mock_image_gen)


_SAMPLE_WARDROBE = [
    {"id": "shirt1", "type": "shirt", "coverage": "top", "color": "#FFFFFF",
     "pattern": "solid", "imageUrl": None},
    {"id": "jeans1", "type": "jeans", "coverage": "bottom", "color": "#001F5B",
     "pattern": "solid", "imageUrl": None},
    {"id": "jacket1", "type": "jacket", "coverage": "layer", "color": "#000000",
     "pattern": "solid", "imageUrl": None},
    {"id": "dress1", "type": "dress", "coverage": "fullbody", "color": "#FF69B4",
     "pattern": "floral", "imageUrl": None},
]

_SAMPLE_COMBINATIONS = _CombinationsWrapper(
    combinations=[
        OutfitCombination(item_ids=["shirt1", "jeans1"], style_note="Casual chic"),
        OutfitCombination(item_ids=["shirt1", "jeans1", "jacket1"], style_note="Smart casual"),
        OutfitCombination(item_ids=["dress1"], style_note="Feminine flair"),
        OutfitCombination(item_ids=["dress1", "jacket1"], style_note="Layered elegance"),
    ]
)


@pytest.mark.asyncio
async def test_generate_returns_four_combinations(service: SuggestionService) -> None:
    with (
        patch.object(service, "_fetch_wardrobe", new=AsyncMock(return_value=_SAMPLE_WARDROBE)),
        patch.object(service, "_select_combinations", new=AsyncMock(
            return_value=_SAMPLE_COMBINATIONS.combinations
        )),
        patch.object(service, "_build_outfit_image", new=AsyncMock(return_value=b"img")),
        patch.object(service, "_generate_mannequin", new=AsyncMock(return_value=b"manikin")),
        patch.object(service, "_upload_and_save", new=AsyncMock()),
    ):
        result = await service.generate(SuggestionRequest(user_id="u1", mood="casual"))

    assert len(result.combinations) == 4
    assert result.batch_id != ""


@pytest.mark.asyncio
async def test_generate_empty_wardrobe_returns_empty(service: SuggestionService) -> None:
    with patch.object(service, "_fetch_wardrobe", new=AsyncMock(return_value=[])):
        result = await service.generate(SuggestionRequest(user_id="u1", mood="work"))

    assert result.combinations == []
    assert result.batch_id == ""


@pytest.mark.asyncio
async def test_build_outfit_image_no_urls_returns_placeholder(
    service: SuggestionService,
) -> None:
    # Items with no imageUrl should produce a valid JPEG placeholder
    result = await service._build_outfit_image(_SAMPLE_WARDROBE, ["shirt1", "jeans1"])
    assert isinstance(result, bytes)
    assert len(result) > 0


@pytest.mark.asyncio
async def test_upload_and_save_called_for_each_combo(service: SuggestionService) -> None:
    upload_mock = AsyncMock()
    with (
        patch.object(service, "_fetch_wardrobe", new=AsyncMock(return_value=_SAMPLE_WARDROBE)),
        patch.object(service, "_select_combinations", new=AsyncMock(
            return_value=_SAMPLE_COMBINATIONS.combinations
        )),
        patch.object(service, "_build_outfit_image", new=AsyncMock(return_value=b"img")),
        patch.object(service, "_generate_mannequin", new=AsyncMock(return_value=b"manikin")),
        patch.object(service, "_upload_and_save", new=upload_mock),
    ):
        await service.generate(SuggestionRequest(user_id="u1", mood="brunch"))

    assert upload_mock.await_count == 4
