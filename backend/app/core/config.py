from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Smart Village Intelligence API"
    environment: str = "development"
    secret_key: str = "development-only-change-this-secret"
    access_token_expire_minutes: int = 60
    database_url: str = "sqlite:///./smart_village.db"
    cors_origins: str = (
        "http://localhost:3000,http://127.0.0.1:3000,"
        "http://localhost:8080,http://127.0.0.1:8080,"
        "http://localhost:8081,http://127.0.0.1:8081"
    )
    escalation_after_hours: int = 72
    minimum_prediction_samples: int = 100

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False, extra="ignore")

    @model_validator(mode="after")
    def validate_runtime_settings(self) -> "Settings":
        if self.access_token_expire_minutes <= 0:
            raise ValueError("ACCESS_TOKEN_EXPIRE_MINUTES must be greater than zero")
        if self.escalation_after_hours <= 0:
            raise ValueError("ESCALATION_AFTER_HOURS must be greater than zero")
        if self.minimum_prediction_samples < 1:
            raise ValueError("MINIMUM_PREDICTION_SAMPLES must be greater than zero")

        if self.environment.strip().lower() in {"production", "prod"}:
            if len(self.secret_key) < 32 or self.secret_key.strip().lower().startswith(
                ("development", "replace-with")
            ):
                raise ValueError(
                    "Production SECRET_KEY must be a unique value of at least 32 characters"
                )
            if not self.database_url.lower().startswith(("postgresql://", "postgresql+")):
                raise ValueError("Production DATABASE_URL must use PostgreSQL")
            if "*" in self.cors_origin_list:
                raise ValueError("Wildcard CORS_ORIGINS are not allowed in production")
        return self

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
