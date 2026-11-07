from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator


class AnalyzeComplaintRequest(BaseModel):
    complaint_id: int | None = Field(default=None, gt=0)
    complaint_text: str | None = Field(default=None, min_length=5, max_length=5000)
    language: str = Field(default="english", min_length=2, max_length=30)
    affected_people: int = Field(default=1, ge=1, le=1_000_000)
    complaint_age_hours: float = Field(default=0, ge=0, le=8760)
    repeated_complaints: int = Field(default=0, ge=0, le=1_000_000)
    location_importance: int = Field(default=0, ge=0, le=10)
    evidence_media_type: str | None = None
    evidence_size_bytes: int | None = Field(default=None, ge=1)

    @model_validator(mode="after")
    def require_text_or_id(self) -> "AnalyzeComplaintRequest":
        if self.complaint_id is None and not self.complaint_text:
            raise ValueError("Provide complaint_id or complaint_text")
        self.language = self.language.strip().lower()
        return self


class DuplicateResponse(BaseModel):
    possible_duplicate: bool
    matching_complaint_id: int | None
    similarity_score: float | None


class EvidenceResponse(BaseModel):
    status: str


class AIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    complaint_id: int | None
    model_status: str = "development_baseline"
    category: str
    confidence: float
    severity: str
    severity_explanation: str
    priority_score: float
    priority_level: str
    priority_explanation: str
    possible_duplicate: bool
    matching_complaint_id: int | None
    similarity_score: float | None
    recommended_department: str
    evidence_status: str
    analysis_timestamp: datetime
