"""Pydantic schemas for suggestion requests and responses."""

from pydantic import BaseModel, Field

from app.schemas.clothing import ClothingMetadata


class SuggestionRequest(BaseModel):
    user_id: str = Field(description="Firebase UID of the requesting user")
    mood: str = Field(description="Dress code / mood: casual | work | brunch | night | active")


class OutfitCombination(BaseModel):
    item_ids: list[str] = Field(
        default_factory=list,
        description="Wardrobe item IDs included in this outfit (2–4 items)",
    )
    style_note: str = Field(
        default="",
        description="Short styling tip explaining why these pieces work together",
    )


class SuggestionResponse(BaseModel):
    combinations: list[OutfitCombination] = Field(default_factory=list)
    batch_id: str = Field(default="", description="Firestore batch document ID")


class MetadataRequest(BaseModel):
    user_id: str
    item_id: str
    image_url: str = Field(description="Firebase Storage download URL of the uploaded image")


class MetadataResponse(BaseModel):
    item_id: str
    metadata: ClothingMetadata


class BatchSuggestionResponse(BaseModel):
    processed_users: int = 0
    total_batches: int = 0
