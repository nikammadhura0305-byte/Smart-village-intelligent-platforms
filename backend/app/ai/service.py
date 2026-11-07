from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ai.classifier import ComplaintClassifier
from app.ai.departments import recommend_department
from app.ai.duplicate import find_duplicate
from app.ai.evidence import EvidenceAnalysisService
from app.ai.priority import calculate_priority
from app.ai.severity import EMERGENCY_TERMS, detect_severity
from app.models import AIAnalysis, Complaint


@dataclass(frozen=True)
class AnalysisOutcome:
    analysis: AIAnalysis
    model_status: str


class ComplaintAnalysisService:
    def __init__(self, classifier: ComplaintClassifier | None = None) -> None:
        self.classifier = classifier or ComplaintClassifier()
        self.evidence = EvidenceAnalysisService()

    def analyze(
        self,
        db: Session,
        text: str,
        language: str,
        complaint_id: int | None = None,
        affected_people: int = 1,
        complaint_age_hours: float = 0,
        repeated_complaints: int = 0,
        location_importance: int = 0,
        evidence_media_type: str | None = None,
        evidence_size_bytes: int | None = None,
    ) -> AnalysisOutcome:
        category, confidence, model_status = self.classifier.predict(text, language)
        severity = detect_severity(text, affected_people)
        emergency_keyword_count = sum(term in text.lower() for term in EMERGENCY_TERMS)
        priority = calculate_priority(
            severity=severity.level,
            affected_people=affected_people,
            complaint_age_hours=complaint_age_hours,
            repeated_complaints=repeated_complaints,
            location_importance=location_importance,
            emergency_keyword_count=emergency_keyword_count,
        )

        existing_query = select(Complaint.id, Complaint.text)
        if complaint_id is not None:
            existing_query = existing_query.where(Complaint.id != complaint_id)
        existing = [(int(row.id), row.text) for row in db.execute(existing_query).all()]
        duplicate = find_duplicate(text, existing)
        evidence = self.evidence.analyze(evidence_media_type, evidence_size_bytes)

        analysis = AIAnalysis(
            complaint_id=complaint_id,
            category=category,
            confidence=confidence,
            severity=severity.level,
            severity_explanation=severity.explanation,
            priority_score=priority.score,
            priority_level=priority.level,
            priority_explanation=priority.explanation,
            possible_duplicate=duplicate.possible_duplicate,
            matching_complaint_id=duplicate.matching_complaint_id,
            similarity_score=duplicate.similarity_score,
            recommended_department=recommend_department(category),
            evidence_status=evidence.status,
            analysis_timestamp=datetime.now(UTC),
        )
        db.add(analysis)
        db.commit()
        db.refresh(analysis)
        return AnalysisOutcome(analysis=analysis, model_status=model_status)
