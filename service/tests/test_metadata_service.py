"""Tests for MetadataService using mock providers."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.providers.llm.mock import MockLLMProvider
from app.schemas.clothing import (
    ClothingMetadata,
    ClothingType,
    CoverageType,
    PatternType,
)
from app.schemas.suggestion import MetadataRequest
from app.services.metadata_service import MetadataService


@pytest.fixture
def mock_llm() -> MockLLMProvider:
    return MockLLMProvider()


@pytest.fixture
def service(mock_llm: MockLLMProvider) -> MetadataService:
    return MetadataService(mock_llm)


@pytest.mark.asyncio
async def test_extract_and_save_returns_metadata(service: MetadataService) -> None:
    expected_metadata = ClothingMetadata(
        clothing_type=ClothingType.shirt,
        coverage=CoverageType.top,
        color="#FFFFFF",
        pattern=PatternType.solid,
        short_description="A plain white shirt",
    )

    with (
        patch.object(service, "_fetch_image", new=AsyncMock(return_value=b"fake_image")),
        patch.object(service._llm, "describe_image", new=AsyncMock(return_value="white shirt")),
        patch.object(service._llm, "complete_structured", new=AsyncMock(return_value=expected_metadata)),
        patch.object(service, "_patch_firestore", new=AsyncMock()),
    ):
        request = MetadataRequest(
            user_id="user123",
            item_id="item456",
            image_url="https://example.com/image.jpg",
        )
        response = await service.extract_and_save(request)

    assert response.item_id == "item456"
    assert response.metadata.clothing_type == ClothingType.shirt
    assert response.metadata.coverage == CoverageType.top


@pytest.mark.asyncio
async def test_extract_calls_fetch_image(service: MetadataService) -> None:
    fake_metadata = ClothingMetadata(
        clothing_type=ClothingType.jeans,
        coverage=CoverageType.bottom,
        color="#001F5B",
        pattern=PatternType.solid,
        short_description="Dark blue jeans",
    )

    fetch_mock = AsyncMock(return_value=b"img_bytes")
    with (
        patch.object(service, "_fetch_image", new=fetch_mock),
        patch.object(service._llm, "describe_image", new=AsyncMock(return_value="blue jeans")),
        patch.object(service._llm, "complete_structured", new=AsyncMock(return_value=fake_metadata)),
        patch.object(service, "_patch_firestore", new=AsyncMock()),
    ):
        await service.extract_and_save(
            MetadataRequest(
                user_id="u1", item_id="i1", image_url="https://example.com/img.jpg"
            )
        )

    fetch_mock.assert_awaited_once_with("https://example.com/img.jpg")


@pytest.mark.asyncio
async def test_patch_firestore_called_with_correct_ids(service: MetadataService) -> None:
    fake_metadata = ClothingMetadata(
        clothing_type=ClothingType.dress,
        coverage=CoverageType.fullbody,
        color="#FF0000",
        pattern=PatternType.floral,
        short_description="Red floral dress",
    )

    patch_mock = AsyncMock()
    with (
        patch.object(service, "_fetch_image", new=AsyncMock(return_value=b"img")),
        patch.object(service._llm, "describe_image", new=AsyncMock(return_value="red dress")),
        patch.object(service._llm, "complete_structured", new=AsyncMock(return_value=fake_metadata)),
        patch.object(service, "_patch_firestore", new=patch_mock),
    ):
        await service.extract_and_save(
            MetadataRequest(user_id="myuser", item_id="myitem", image_url="https://x.com/i.jpg")
        )

    patch_mock.assert_awaited_once_with("myuser", "myitem", fake_metadata)
