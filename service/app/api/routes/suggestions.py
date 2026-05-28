"""POST /v1/suggestions — generate 4 outfit suggestions for a user+mood."""

from fastapi import APIRouter, Depends, Request

from app.api.dependencies import verify_firebase_token
from app.schemas.suggestion import SuggestionRequest, SuggestionResponse
from app.services.suggestion_service import SuggestionService

router = APIRouter()


@router.post("", response_model=SuggestionResponse)
async def generate_suggestions(
    body: SuggestionRequest,
    request: Request,
    _token: dict = Depends(verify_firebase_token),
) -> SuggestionResponse:
    service: SuggestionService = request.app.state.suggestion_service
    return await service.generate(body)
