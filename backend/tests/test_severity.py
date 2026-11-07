from app.ai.severity import detect_severity


def test_english_emergency_term_is_high():
    result = detect_severity("The ambulance service is unavailable")
    assert result.level in {"High", "Critical"}


def test_large_number_of_people_increases_severity():
    small_group = detect_severity("Water supply is interrupted", affected_people=1)
    large_group = detect_severity("Water supply is interrupted", affected_people=100)

    assert large_group.score > small_group.score


def test_marathi_water_outage_is_detected():
    result = detect_severity("आमच्या गावात तीन दिवसांपासून पाणी आले नाही")
    assert result.level in {"Medium", "High", "Critical"}

def test_sparking_transformer_is_high_severity():
    result = detect_severity(
        "The transformer is sparking near the houses"
    )
    assert result.level == "High"
    assert result.score == 4


def test_hindi_emergency_term_is_detected():
    result = detect_severity("गाँव में बिजली का करंट फैल गया है तुरंत मदद भेजें", affected_people=30)
    assert result.level in {"High", "Critical"}
    assert any("तुरंत" in f or "करंट" in f for f in result.features)


def test_hindi_outage_term_is_detected():
    result = detect_severity("गाँव में दो दिन से बिजली गुल है")
    assert result.level in {"Medium", "High", "Critical"}
    assert any("बिजली गुल" in f for f in result.features)


def test_marathi_emergency_fire_is_critical_or_high():
    result = detect_severity("डीपीला आग लागली आहे तातडीने या", affected_people=10)
    assert result.level in {"High", "Critical"}
    assert any("आग" in f or "तातडीने" in f for f in result.features)