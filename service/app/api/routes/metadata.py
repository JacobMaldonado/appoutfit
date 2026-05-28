"""POST /v1/metadata — extract structured metadata from a clothing image."""

from fastapi import APIRouter, Depends, Request

from app.api.dependencies import verify_firebase_token
from app.schemas.suggestion import MetadataRequest, MetadataResponse
from app.services.metadata_service import MetadataService

router = APIRouter()


@router.post("", response_model=MetadataResponse)
async def extract_metadata(
    body: MetadataRequest,
    request: Request,
    _token: dict = Depends(verify_firebase_token),
) -> MetadataResponse:
    service: MetadataService = request.app.state.metadata_service
    return await service.extract_and_save(body)
