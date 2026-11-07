from collections import Counter, defaultdict
from datetime import UTC, datetime

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import AIAnalysis, Complaint


def complaint_rows(
    db: Session,
    village_id: int | None = None,
    include_all_villages: bool = False,
    village_ids: list[int] | None = None,
) -> list[tuple[Complaint, AIAnalysis | None]]:
    query = select(Complaint)
    if village_ids is not None:
        if not village_ids:
            return []
        query = query.where(Complaint.village_id.in_(village_ids))
    elif not include_all_villages:
        if village_id is None:
            return []
        query = query.where(Complaint.village_id == village_id)
    complaints = db.scalars(
        query.order_by(desc(Complaint.created_at), desc(Complaint.id))
    ).all()
    rows: list[tuple[Complaint, AIAnalysis | None]] = []
    for complaint in complaints:
        analysis = db.scalar(
            select(AIAnalysis)
            .where(AIAnalysis.complaint_id == complaint.id)
            .order_by(desc(AIAnalysis.analysis_timestamp))
            .limit(1)
        )
        rows.append((complaint, analysis))
    return rows


def build_analytics(
    db: Session,
    village_id: int | None,
    include_all_villages: bool,
    village_ids: list[int] | None = None,
) -> dict[str, object]:
    rows = complaint_rows(db, village_id, include_all_villages, village_ids)
    complaint_trends = Counter()
    category_trends = Counter()
    department_workload = Counter()
    repeated_areas: list[dict[str, int | str | None]] = []
    severity_trends = Counter()
    heat_map: list[dict[str, int | float | str | None]] = []
    resolution_hours: list[float] = []

    for complaint, analysis in rows:
        month = complaint.created_at.strftime("%Y-%m") if complaint.created_at else "unknown"
        complaint_trends[month] += 1
        if analysis:
            category_trends[f"{month}|{analysis.category}"] += 1
            severity_trends[analysis.severity] += 1
        department_workload[complaint.assigned_department or "Unassigned"] += 1
        if complaint.repeated_complaints > 0:
            repeated_areas.append(
                {
                    "village_id": complaint.village_id,
                    "complaint_id": complaint.id,
                    "repeated_complaints": complaint.repeated_complaints,
                }
            )
        if complaint.latitude is not None and complaint.longitude is not None:
            heat_map.append(
                {
                    "complaint_id": complaint.id,
                    "latitude": complaint.latitude,
                    "longitude": complaint.longitude,
                    "category": analysis.category if analysis else None,
                    "severity": analysis.severity if analysis else None,
                }
            )
        if complaint.status in {"Resolved", "Closed"} and complaint.created_at and complaint.completion_date:
            resolution_hours.append((complaint.completion_date - complaint.created_at).total_seconds() / 3600)

    category_rows = [
        {"month": key.split("|", 1)[0], "category": key.split("|", 1)[1], "count": value}
        for key, value in sorted(category_trends.items())
    ]
    repeated_areas.sort(key=lambda item: int(item["repeated_complaints"]), reverse=True)
    return {
        "complaint_trends": [{"month": month, "count": count} for month, count in sorted(complaint_trends.items())],
        "category_trends": category_rows,
        "department_workload": dict(sorted(department_workload.items())),
        "repeated_issue_areas": repeated_areas,
        "resolution_time": {
            "resolved_count": len(resolution_hours),
            "average_hours": round(sum(resolution_hours) / len(resolution_hours), 2) if resolution_hours else None,
            "minimum_hours": round(min(resolution_hours), 2) if resolution_hours else None,
            "maximum_hours": round(max(resolution_hours), 2) if resolution_hours else None,
        },
        "pending_complaints": sum(complaint.status not in {"Resolved", "Closed"} for complaint, _ in rows),
        "severity_trends": dict(sorted(severity_trends.items())),
        "heat_map": heat_map,
    }


def build_prediction(
    db: Session,
    village_id: int | None,
    include_all_villages: bool,
    village_ids: list[int] | None = None,
) -> dict[str, object]:
    rows = complaint_rows(db, village_id, include_all_villages, village_ids)
    sample_count = len(rows)
    if sample_count < settings.minimum_prediction_samples:
        return {
            "status": "insufficient_data",
            "message": (
                f"Prediction is disabled: {sample_count} complaints are available, "
                f"but {settings.minimum_prediction_samples} historical records are required."
            ),
            "required_samples": settings.minimum_prediction_samples,
            "sample_count": sample_count,
            "predictions": [],
        }

    repeated_categories = Counter(
        analysis.category
        for complaint, analysis in rows
        if analysis and complaint.repeated_complaints > 0
    )
    predictions = [
        {"category": category, "repeat_count": count, "confidence": None}
        for category, count in repeated_categories.most_common()
    ]
    return {
        "status": "baseline_available",
        "message": "Historical frequency baseline is available; validate it prospectively before operational use.",
        "required_samples": settings.minimum_prediction_samples,
        "sample_count": sample_count,
        "predictions": predictions,
    }


def build_report(
    db: Session,
    village_id: int | None,
    include_all_villages: bool,
    village_ids: list[int] | None = None,
) -> dict[str, object]:
    rows = complaint_rows(db, village_id, include_all_villages, village_ids)
    category_counts = Counter(analysis.category for _, analysis in rows if analysis)
    month_counts = Counter(
        complaint.created_at.strftime("%Y-%m") if complaint.created_at else "unknown"
        for complaint, _ in rows
    )
    departments: dict[str, list[tuple[Complaint, AIAnalysis | None]]] = defaultdict(list)
    for complaint, analysis in rows:
        departments[complaint.assigned_department or "Unassigned"].append((complaint, analysis))
    performance = []
    for department, department_rows in sorted(departments.items()):
        resolved = [
            (complaint.completion_date - complaint.created_at).total_seconds() / 3600
            for complaint, _ in department_rows
            if complaint.status in {"Resolved", "Closed"} and complaint.created_at and complaint.completion_date
        ]
        performance.append(
            {
                "department": department,
                "total": len(department_rows),
                "resolved": sum(complaint.status in {"Resolved", "Closed"} for complaint, _ in department_rows),
                "average_resolution_hours": round(sum(resolved) / len(resolved), 2) if resolved else None,
            }
        )
    critical = [
        {"complaint_id": complaint.id, "category": analysis.category, "severity": analysis.severity}
        for complaint, analysis in rows
        if analysis and analysis.severity == "Critical"
    ]
    return {
        "generated_at": datetime.now(UTC),
        "summary": {
            "total": len(rows),
            "resolved": sum(complaint.status in {"Resolved", "Closed"} for complaint, _ in rows),
            "pending": sum(complaint.status not in {"Resolved", "Closed"} for complaint, _ in rows),
        },
        "complaints_by_category": dict(sorted(category_counts.items())),
        "complaints_by_month": dict(sorted(month_counts.items())),
        "department_performance": performance,
        "critical_issues": critical,
        "village_issue_summary": [],
    }
