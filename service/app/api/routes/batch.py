"""POST /v1/batch-suggestions — daily all-users × all-moods suggestion job."""

from fastapi import APIRouter, Depends, Request

from app.api.dependencies import verify_scheduler_token
from app.schemas.suggestion import BatchSuggestionResponse
from app.services.batch_service import BatchService

router = APIRouter()


@router.post("", response_model=BatchSuggestionResponse)
async def batch_suggestions(
    request: Request,
    _auth: None = Depends(verify_scheduler_token),
) -> BatchSuggestionResponse:
    service: BatchService = request.app.state.batch_service
    return await service.run()
