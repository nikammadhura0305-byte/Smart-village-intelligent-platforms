from dataclasses import dataclass

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

DEFAULT_DUPLICATE_THRESHOLD = 0.45


@dataclass(frozen=True)
class DuplicateResult:
    possible_duplicate: bool
    matching_complaint_id: int | None
    similarity_score: float | None


def find_duplicate(text: str, existing: list[tuple[int, str]], threshold: float = DEFAULT_DUPLICATE_THRESHOLD) -> DuplicateResult:
    if not existing:
        return DuplicateResult(False, None, None)

    documents = [text] + [complaint_text for _, complaint_text in existing]
    matrix = TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True).fit_transform(documents)
    scores = cosine_similarity(matrix[0:1], matrix[1:]).ravel()
    best_index = int(scores.argmax())
    best_score = float(scores[best_index])
    matching_id = existing[best_index][0]
    return DuplicateResult(best_score >= threshold, matching_id if best_score >= threshold else None, round(best_score, 4))
