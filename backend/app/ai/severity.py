from dataclasses import dataclass


@dataclass(frozen=True)
class SeverityResult:
    level: str
    score: int
    features: list[str]
    explanation: str


EMERGENCY_TERMS = {
    # English
    "urgent",
    "emergency",
    "danger",
    "critical",
    "death",
    "dying",
    "hospital",
    "ambulance",
    "fire",
    "sparking",
    "accident",
    # Marathi
    "तातडीचे",
    "तातडीने",
    "धोका",
    "धोकादायक",
    "मृत्यू",
    "दवाखाना",
    "रुग्णवाहिका",
    "आग",
    "अपघात",
    "शॉक",
    # Hindi
    "तुरंत",
    "आपातकालीन",
    "खतरा",
    "गंभीर",
    "मौत",
    "अस्पताल",
    "एम्बुलेंस",
    "आग",
    "दुर्घटना",
    "करंट",
}
OUTAGE_TERMS = {
    # English
    "no water",
    "no electricity",
    "power cut",
    "unavailable",
    "not arrived",
    "broken",
    "overflowing",
    "blocked",
    # Marathi
    "पाणी आले नाही",
    "पाणीपुरवठा बंद",
    "पाणी मिळत नाही",
    "वीज नाही",
    "वीजपुरवठा बंद",
    "बंद आहेत",
    "खराब",
    "तुटलेली",
    "तुंबलेली",
    "गळती",
    # Hindi
    "पानी नहीं आ रहा",
    "पानी नहीं आया",
    "पानी की समस्या",
    "बिजली नहीं है",
    "बिजली गुल",
    "बिजली बंद",
    "सड़क खराब",
    "गड्ढे",
    "कचरा",
    "नाली बंद",
    "जाम",
    "खराब है",
    "टूटा हुआ",
}


def detect_severity(text: str, affected_people: int = 1) -> SeverityResult:
    normalized = text.lower()
    features: list[str] = []
    score = 0

    matched_emergency = sorted(term for term in EMERGENCY_TERMS if term in normalized)
    if matched_emergency:
        score += 4
        features.append(f"emergency terms: {', '.join(matched_emergency)}")

    matched_outage = sorted(term for term in OUTAGE_TERMS if term in normalized)
    if matched_outage:
        score += 2
        features.append(f"service outage terms: {', '.join(matched_outage)}")

    if affected_people >= 100:
        score += 3
        features.append("100 or more people affected")
    elif affected_people >= 25:
        score += 2
        features.append("25 or more people affected")
    elif affected_people >= 5:
        score += 1
        features.append("5 or more people affected")

    if score >= 7:
        level = "Critical"
    elif score >= 4:
        level = "High"
    elif score >= 2:
        level = "Medium"
    else:
        level = "Low"

    if not features:
        features.append("no emergency or outage indicators detected")
    explanation = "Severity uses transparent text indicators and affected-person count: " + "; ".join(features) + "."
    return SeverityResult(level=level, score=score, features=features, explanation=explanation)
