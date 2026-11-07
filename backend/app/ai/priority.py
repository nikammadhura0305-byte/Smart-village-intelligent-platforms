from dataclasses import dataclass


@dataclass(frozen=True)
class PriorityResult:
    score: float
    level: str
    explanation: str


SEVERITY_POINTS = {"Low": 10, "Medium": 35, "High": 65, "Critical": 90}


def calculate_priority(
    severity: str,
    affected_people: int,
    complaint_age_hours: float,
    repeated_complaints: int,
    location_importance: int,
    emergency_keyword_count: int,
) -> PriorityResult:
    severity_points = SEVERITY_POINTS[severity]
    affected_points = min(20.0, affected_people / 5)
    emergency_points = min(10.0, emergency_keyword_count * 5)
    age_points = min(10.0, complaint_age_hours / 24)
    repeated_points = min(10.0, repeated_complaints * 3)
    location_points = min(10.0, max(0, location_importance))
    score = round(
        min(
            100.0,
            severity_points
            + affected_points
            + emergency_points
            + age_points
            + repeated_points
            + location_points,
        ),
        2,
    )

    if score >= 80:
        level = "Critical"
    elif score >= 60:
        level = "High"
    elif score >= 30:
        level = "Medium"
    else:
        level = "Low"

    explanation = (
        f"Priority = severity {severity_points}/90 + affected people {affected_points:.1f}/20 + "
        f"emergency keywords {emergency_points:.1f}/10 + age {age_points:.1f}/10 + "
        f"repeated complaints {repeated_points:.1f}/10 + location importance {location_points:.1f}/10."
    )
    return PriorityResult(score=score, level=level, explanation=explanation)
