from pathlib import Path
from typing import Any

import joblib

ARTIFACT_PATH = Path(__file__).resolve().parents[2] / "artifacts" / "complaint_classifier.joblib"


class ClassifierUnavailable(RuntimeError):
    pass


class ComplaintClassifier:
    def __init__(self, artifact_path: Path = ARTIFACT_PATH) -> None:
        self.artifact_path = artifact_path
        self._artifact: dict[str, Any] | None = None

    def _load(self) -> dict[str, Any]:
        if self._artifact is None:
            if not self.artifact_path.exists():
                raise ClassifierUnavailable(
                    "Complaint classifier artifact is missing. Run "
                    "python -m app.ai.train_baseline first."
                )
            self._artifact = joblib.load(self.artifact_path)
        return self._artifact

    def predict(self, text: str, language: str) -> tuple[str, float, str]:
        artifact = self._load()
        model = artifact["model"]
        model_input = [f"{language.lower()} {text}"]
        category = str(model.predict(model_input)[0])
        probabilities = model.predict_proba(model_input)[0]
        confidence = float(max(probabilities))
        return category, confidence, str(artifact.get("status", "development_baseline"))
