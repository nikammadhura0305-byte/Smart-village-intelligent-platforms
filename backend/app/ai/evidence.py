from dataclasses import dataclass


SUPPORTED_MEDIA_TYPES = {
    "image/jpeg",
    "image/png",
    "video/mp4",
    "video/quicktime",
}
MAX_EVIDENCE_BYTES = 50 * 1024 * 1024


@dataclass(frozen=True)
class EvidenceResult:
    status: str
    message: str


class EvidenceAnalysisService:
    """Validation is implemented; trained computer-vision inference is pending."""

    def analyze(self, media_type: str | None, size_bytes: int | None) -> EvidenceResult:
        if media_type is None and size_bytes is None:
            return EvidenceResult("not_provided", "No photo or video evidence was supplied.")
        if media_type not in SUPPORTED_MEDIA_TYPES:
            return EvidenceResult("invalid", "Evidence type is not a supported JPEG, PNG, MP4, or MOV file.")
        if size_bytes is None or size_bytes <= 0 or size_bytes > MAX_EVIDENCE_BYTES:
            return EvidenceResult("invalid", "Evidence size must be between 1 byte and 50 MB.")
        return EvidenceResult(
            "pending_model_integration",
            "Evidence passed validation. Computer-vision model integration is pending; no visual claim was made.",
        )
