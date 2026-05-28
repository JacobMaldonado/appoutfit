from enum import Enum
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Environment(str, Enum):
    local = "local"
    dev = "dev"
    prod = "prod"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    env: Environment = Environment.local
    port: int = 8080

    # AI providers (not required in local env — mocks are used instead)
    gemini_api_key: str = ""
    bfl_api_key: str = ""

    # Firebase (not required in local env)
    firebase_project_id: str = ""
    # Path to a service account JSON file, or base-64-encoded JSON string
    firebase_service_account_json: str = ""

    # Cloud Scheduler service account for batch endpoint OIDC verification
    batch_scheduler_sa_email: str = ""

    @property
    def use_real_providers(self) -> bool:
        return self.env != Environment.local


@lru_cache
def get_settings() -> Settings:
    return Settings()
