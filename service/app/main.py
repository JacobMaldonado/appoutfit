"""FastAPI application entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import batch, metadata, suggestions
from app.core.config import Environment, get_settings
from app.core.firebase_client import initialise_firebase
from app.providers.image_gen.bfl import BFLFluxProvider
from app.providers.image_gen.mock import MockImageGenProvider
from app.providers.llm.gemini import GeminiProvider
from app.providers.llm.mock import MockLLMProvider
from app.services.batch_service import BatchService
from app.services.metadata_service import MetadataService
from app.services.suggestion_service import SuggestionService

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):  # type: ignore[type-arg]
    settings = get_settings()
    use_firebase = settings.use_real_providers

    logger.info("=" * 60)
    logger.info("  Clo·set API starting up")
    logger.info("  ENV            : %s", settings.env)
    logger.info("  Firebase       : %s", "enabled" if use_firebase else "disabled (local mocks)")
    logger.info("  LLM / Image-gen: %s", "Gemini + BFL Flux" if use_firebase else "mocks")
    logger.info("=" * 60)

    if use_firebase:
        if not settings.firebase_service_account_json:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_JSON is required when ENV != local. "
                "Set it in your .env file (file path or base-64 JSON)."
            )
        if not settings.firebase_storage_bucket:
            raise ValueError(
                "FIREBASE_STORAGE_BUCKET is required when ENV != local. "
                "Set it to your bucket name, e.g. 'my-project.firebasestorage.app'."
            )
        initialise_firebase(
            settings.firebase_service_account_json,
            settings.firebase_project_id,
            settings.firebase_storage_bucket,
        )
        llm = GeminiProvider(settings.gemini_api_key)
        image_gen = BFLFluxProvider(settings.bfl_api_key)
    else:
        llm = MockLLMProvider()
        image_gen = MockImageGenProvider()

    suggestion_svc = SuggestionService(llm, image_gen, use_firebase=use_firebase)
    app.state.metadata_service = MetadataService(llm, use_firebase=use_firebase)
    app.state.suggestion_service = suggestion_svc
    app.state.batch_service = BatchService(suggestion_svc, use_firebase=use_firebase)

    yield
    logger.info("Clo·set API shut down")


def create_app() -> FastAPI:
    app = FastAPI(
        title="Clo·set API",
        description="Outfit suggestion and wardrobe metadata service",
        version="1.0.0",
        lifespan=lifespan,
    )
    app.include_router(metadata.router, prefix="/v1/metadata", tags=["metadata"])
    app.include_router(suggestions.router, prefix="/v1/suggestions", tags=["suggestions"])
    app.include_router(batch.router, prefix="/v1/batch-suggestions", tags=["batch"])

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok"}

    return app


app = create_app()
