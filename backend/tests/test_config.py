import pytest
from pydantic import ValidationError

from app.core.config import Settings


def make_settings(**overrides: str) -> Settings:
    values = {
        "environment": "development",
        "secret_key": "development-only-change-this-secret",
        "database_url": "sqlite:///./smart_village.db",
        "cors_origins": "http://localhost:3000",
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)


def test_development_settings_allow_sqlite_and_default_secret() -> None:
    settings = make_settings()

    assert settings.database_url == "sqlite:///./smart_village.db"


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        (
            {
                "environment": "production",
                "secret_key": "replace-with-a-long-random-secret",
                "database_url": "postgresql://db.example/smart_village",
            },
            "SECRET_KEY",
        ),
        (
            {
                "environment": "production",
                "secret_key": "a" * 40,
                "database_url": "sqlite:///./smart_village.db",
            },
            "DATABASE_URL",
        ),
        (
            {
                "environment": "production",
                "secret_key": "a" * 40,
                "database_url": "postgresql://db.example/smart_village",
                "cors_origins": "*",
            },
            "CORS_ORIGINS",
        ),
    ],
)
def test_production_settings_reject_insecure_values(
    overrides: dict[str, str],
    message: str,
) -> None:
    with pytest.raises(ValidationError, match=message):
        make_settings(**overrides)


def test_production_settings_accept_postgresql_and_explicit_origins() -> None:
    settings = make_settings(
        environment="production",
        secret_key="a-unique-production-secret-key-value",
        database_url="postgresql+psycopg://db.example/smart_village",
        cors_origins="https://officer.example.gov",
    )

    assert settings.cors_origin_list == ["https://officer.example.gov"]


@pytest.mark.parametrize("value", ["0", "-1"])
def test_access_token_expiry_must_be_positive(value: str) -> None:
    with pytest.raises(ValidationError, match="ACCESS_TOKEN_EXPIRE_MINUTES"):
        make_settings(access_token_expire_minutes=value)
