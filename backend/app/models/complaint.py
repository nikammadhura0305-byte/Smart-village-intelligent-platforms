from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.user import User, Village


class Complaint(Base):
    __tablename__ = "complaints"

    id: Mapped[int] = mapped_column(primary_key=True)
    text: Mapped[str] = mapped_column(Text)
    language: Mapped[str] = mapped_column(Text, default="english", index=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    village_id: Mapped[int | None] = mapped_column(ForeignKey("villages.id"), nullable=True, index=True)
    affected_people: Mapped[int] = mapped_column(Integer, default=1)
    repeated_complaints: Mapped[int] = mapped_column(Integer, default=0)
    location_importance: Mapped[int] = mapped_column(Integer, default=0)
    lane: Mapped[str | None] = mapped_column(Text, nullable=True)
    lane_number: Mapped[str | None] = mapped_column(Text, nullable=True)
    exact_location: Mapped[str | None] = mapped_column(Text, nullable=True)
    area: Mapped[str | None] = mapped_column(Text, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    evidence_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="Pending", index=True)
    assigned_department: Mapped[str | None] = mapped_column(String(150), nullable=True)
    assigned_officer_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    assigned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expected_resolution_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    action_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    repair_evidence_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    completion_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)

    ai_analyses: Mapped[list["AIAnalysis"]] = relationship(
        back_populates="complaint",
        foreign_keys="AIAnalysis.complaint_id",
    )
    village: Mapped[Village | None] = relationship(foreign_keys=[village_id])
    assigned_officer: Mapped[User | None] = relationship(foreign_keys=[assigned_officer_id])
    verifications: Mapped[list["Verification"]] = relationship(
        back_populates="complaint",
        foreign_keys="Verification.complaint_id",
    )


class AIAnalysis(Base):
    __tablename__ = "ai_analyses"

    id: Mapped[int] = mapped_column(primary_key=True)
    complaint_id: Mapped[int | None] = mapped_column(ForeignKey("complaints.id"), nullable=True, index=True)
    category: Mapped[str] = mapped_column(Text)
    confidence: Mapped[float] = mapped_column(Float)
    severity: Mapped[str] = mapped_column(Text)
    severity_explanation: Mapped[str] = mapped_column(Text)
    priority_score: Mapped[float] = mapped_column(Float)
    priority_level: Mapped[str] = mapped_column(Text)
    priority_explanation: Mapped[str] = mapped_column(Text)
    possible_duplicate: Mapped[bool] = mapped_column(Boolean, default=False)
    matching_complaint_id: Mapped[int | None] = mapped_column(ForeignKey("complaints.id"), nullable=True)
    similarity_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    recommended_department: Mapped[str] = mapped_column(Text)
    evidence_status: Mapped[str] = mapped_column(Text, default="not_provided")
    analysis_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)

    complaint: Mapped[Complaint | None] = relationship(
        back_populates="ai_analyses",
        foreign_keys=[complaint_id],
    )
