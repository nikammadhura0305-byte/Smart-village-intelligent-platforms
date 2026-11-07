CATEGORY_DEPARTMENTS = {
    "Water": "Water Department",
    "Roads": "Public Works/Road Department",
    "Electricity": "Electricity Department",
    "Medical": "Health Department",
    "Sanitation": "Sanitation Department",
    "Agriculture": "Agriculture Department",
    "Education": "Education Department",
    "Drainage": "Drainage Department",
    "Street Light": "Electricity Department",
    "Internet/Network": "Telecommunications Department",
    "Government Documents": "Citizen Services Department",
    "Other": "Gram Panchayat General Services",
}

CATEGORY_ALIASES = {
    "water": "Water",
    "water supply": "Water",
    "water line": "Water",
    "road": "Roads",
    "roads": "Roads",
    "road repair": "Roads",
    "drainage": "Drainage",
    "electricity": "Electricity",
    "street light": "Street Light",
    "streetlight": "Street Light",
    "healthcare": "Medical",
    "health": "Medical",
    "medical": "Medical",
    "sanitation": "Sanitation",
    "waste": "Sanitation",
    "garbage": "Sanitation",
    "agriculture": "Agriculture",
    "education": "Education",
    "government documents": "Government Documents",
    "documents": "Government Documents",
    "network": "Internet/Network",
    "internet": "Internet/Network",
    "internet/network": "Internet/Network",
    "other": "Other",
    "general services": "Other",
}


def normalize_category_name(category: str | None) -> str | None:
    if category is None:
        return None
    normalized = category.strip().lower().replace("_", " ")
    if not normalized:
        return None
    return CATEGORY_ALIASES.get(normalized, category.strip())


def recommend_department(category: str) -> str:
    normalized = normalize_category_name(category)
    if normalized is None:
        return CATEGORY_DEPARTMENTS["Other"]
    return CATEGORY_DEPARTMENTS.get(normalized, CATEGORY_DEPARTMENTS["Other"])
