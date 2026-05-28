"""Tests for Pydantic schemas and mock providers."""

from __future__ import annotations

import pytest

from app.providers.image_gen.mock import MockImageGenProvider
from app.providers.llm.mock import MockLLMProvider
from app.schemas.clothing import (
    ClothingMetadata,
    ClothingType,
    CoverageType,
    PatternType,
)
from app.schemas.suggestion import (
    BatchSuggestionResponse,
    MetadataRequest,
    MetadataResponse,
    OutfitCombination,
    SuggestionRequest,
    SuggestionResponse,
)


# ── Schema round-trip tests ─────────────────────────────────────────────────

def test_clothing_metadata_round_trip() -> None:
    meta = ClothingMetadata(
        clothing_type=ClothingType.blazer,
        coverage=CoverageType.layer,
        color="#1A1A2E",
        pattern=PatternType.plaid,
        short_description="Navy plaid blazer",
    )
    reloaded = ClothingMetadata.model_validate_json(meta.model_dump_json())
    assert reloaded == meta


def test_outfit_combination_defaults() -> None:
    combo = OutfitCombination()
    assert combo.item_ids == []
    assert combo.style_note == ""


def test_suggestion_response_defaults() -> None:
    resp = SuggestionResponse()
    assert resp.combinations == []
    assert resp.batch_id == ""


def test_metadata_request_fields() -> None:
    req = MetadataRequest(
        user_id="u1", item_id="i1", image_url="https://example.com/img.jpg"
    )
    assert req.user_id == "u1"
    assert req.item_id == "i1"


def test_batch_suggestion_response_defaults() -> None:
    resp = BatchSuggestionResponse()
    assert resp.processed_users == 0
    assert resp.total_batches == 0


def test_suggestion_request() -> None:
    req = SuggestionRequest(user_id="abc", mood="work")
    assert req.user_id == "abc"
    assert req.mood == "work"


def test_clothing_type_enum_values() -> None:
    assert ClothingType.shirt == "shirt"
    assert ClothingType.dress == "dress"
    assert CoverageType.fullbody == "fullbody"
    assert PatternType.floral == "floral"


# ── Mock provider tests ─────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_mock_image_gen_returns_bytes() -> None:
    provider = MockImageGenProvider()
    result = await provider.generate("a blue dress")
    assert isinstance(result, bytes)
    assert len(result) > 0


@pytest.mark.asyncio
async def test_mock_llm_describe_image() -> None:
    provider = MockLLMProvider()
    result = await provider.describe_image(b"fake", "describe this")
    assert isinstance(result, str)
    assert len(result) > 0


@pytest.mark.asyncio
async def test_mock_llm_complete_structured_returns_schema_instance() -> None:
    provider = MockLLMProvider()
    result = await provider.complete_structured("some prompt", SuggestionResponse)
    assert isinstance(result, SuggestionResponse)


@pytest.mark.asyncio
async def test_mock_llm_complete_structured_clothing_metadata() -> None:
    provider = MockLLMProvider()
    result = await provider.complete_structured("describe", OutfitCombination)
    assert isinstance(result, OutfitCombination)
