"""FastAPI authentication dependencies.

- verify_firebase_token: validates a Firebase ID token sent by the Flutter app.
- verify_scheduler_token: validates the Google OIDC token sent by Cloud Scheduler.
"""

from __future__ import annotations

import logging

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

import google.auth.transport.requests
import google.oauth2.id_token
from firebase_admin import auth

from app.core.config import Settings, get_settings

_bearer = HTTPBearer()
_logger = logging.getLogger(__name__)


async def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    settings: Settings = Depends(get_settings),
) -> dict:
    """Return the decoded Firebase token payload or raise 401."""
    if not settings.use_real_providers:
        # Local env — skip verification, return a mock payload
        return {"uid": "local-test-user", "email": "local@test.com"}

    try:
        decoded = auth.verify_id_token(credentials.credentials)
        return decoded
    except Exception as exc:
        _logger.warning("Firebase token verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase ID token",
        ) from exc


async def verify_scheduler_token(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    settings: Settings = Depends(get_settings),
) -> None:
    """Validate Cloud Scheduler OIDC token or raise 401."""
    if not settings.use_real_providers:
        return  # Local env — allow all

    try:
        request = google.auth.transport.requests.Request()
        id_info = google.oauth2.id_token.verify_oauth2_token(
            credentials.credentials, request
        )
        if id_info.get("email") != settings.batch_scheduler_sa_email:
            raise ValueError("Unexpected service account email")
    except Exception as exc:
        _logger.warning("Scheduler OIDC verification failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Cloud Scheduler OIDC token",
        ) from exc
