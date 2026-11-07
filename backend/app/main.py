from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.routes import ai, auth, citizen, health, intelligence, notifications, officer, users
from app.core.config import settings
from app.db.init_db import init_db


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_origin_regex=(
        r"https?://(localhost|127\.0\.0\.1|10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})(:\d+)?$"
        if settings.environment.lower() in {"development", "dev"}
        else None
    ),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(health.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(ai.router, prefix="/api/v1")
app.include_router(officer.router, prefix="/api/v1")
app.include_router(citizen.router, prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")
app.include_router(intelligence.router, prefix="/api/v1")
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(ai.router)
app.include_router(officer.router)
app.include_router(citizen.router)
app.include_router(notifications.router)
app.include_router(intelligence.router)
app.mount(
    "/dashboard",
    StaticFiles(directory=Path(__file__).parent / "static" / "officer", html=True),
    name="officer-dashboard",
)
