"""Shared Pydantic schemas for clothing items."""

from enum import Enum

from pydantic import BaseModel, Field


class ClothingType(str, Enum):
    shirt = "shirt"
    blouse = "blouse"
    tshirt = "tshirt"
    tank = "tank"
    sweater = "sweater"
    pants = "pants"
    jeans = "jeans"
    skirt = "skirt"
    shorts = "shorts"
    dress = "dress"
    jumpsuit = "jumpsuit"
    jacket = "jacket"
    coat = "coat"
    cardigan = "cardigan"
    blazer = "blazer"


class CoverageType(str, Enum):
    top = "top"
    bottom = "bottom"
    fullbody = "fullbody"
    layer = "layer"


class PatternType(str, Enum):
    solid = "solid"
    striped = "striped"
    floral = "floral"
    plaid = "plaid"
    printed = "printed"


class ClothingMetadata(BaseModel):
    clothing_type: ClothingType = Field(description="Category of the garment")
    coverage: CoverageType = Field(description="Part of body covered")
    color: str = Field(description="Dominant hex color e.g. #FFFFFF")
    pattern: PatternType = Field(description="Surface pattern of the garment")
    short_description: str = Field(description="One-sentence style description, max 80 chars")
