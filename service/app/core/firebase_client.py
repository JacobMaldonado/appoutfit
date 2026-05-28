"""Singleton Firebase Admin SDK initialisation."""

import base64
import json
import threading

import firebase_admin
from firebase_admin import credentials

_lock = threading.Lock()
_initialised = False


def initialise_firebase(service_account_json: str, project_id: str) -> None:
    """Initialise Firebase Admin SDK exactly once.

    *service_account_json* may be:
    - an absolute file path to a JSON key file, or
    - a base-64-encoded JSON string.
    """
    global _initialised

    with _lock:
        if _initialised or len(firebase_admin._apps):  # noqa: SLF001
            return

        if service_account_json.startswith("/") or service_account_json.endswith(".json"):
            cred = credentials.Certificate(service_account_json)
        else:
            decoded = base64.b64decode(service_account_json).decode()
            cred = credentials.Certificate(json.loads(decoded))

        firebase_admin.initialize_app(cred, {"projectId": project_id})
        _initialised = True
