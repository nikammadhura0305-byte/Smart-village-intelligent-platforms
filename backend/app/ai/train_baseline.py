from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import joblib
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import FeatureUnion
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

DATASET_PATH = Path(__file__).resolve().parents[2] / "data" / "complaints_sample.csv"
ARTIFACT_PATH = Path(__file__).resolve().parents[2] / "artifacts" / "complaint_classifier.joblib"


def train() -> dict[str, Any]:
    dataset = pd.read_csv(DATASET_PATH)
    model_input = dataset["language"].str.lower() + " " + dataset["text"]
    labels = dataset["category"]
    train_text, test_text, train_labels, test_labels = train_test_split(
        model_input,
        labels,
        test_size=0.5,
        random_state=42,
        stratify=labels,
    )

    model = Pipeline(
        [
            (
                "features",
                FeatureUnion(
                    [
                        ("word_tfidf", TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True)),
                        (
                            "character_tfidf",
                            TfidfVectorizer(
                                analyzer="char_wb",
                                ngram_range=(3, 5),
                                sublinear_tf=True,
                            ),
                        ),
                    ]
                ),
            ),
            ("classifier", LogisticRegression(max_iter=2000, solver="liblinear", random_state=42)),
        ]
    )
    model.fit(train_text, train_labels)
    predictions = model.predict(test_text)
    metrics = {
        "accuracy": float(accuracy_score(test_labels, predictions)),
        "macro_f1": float(f1_score(test_labels, predictions, average="macro", zero_division=0)),
        "classification_report": classification_report(
            test_labels,
            predictions,
            output_dict=True,
            zero_division=0,
        ),
    }
    model.fit(model_input, labels)

    artifact = {
        "model": model,
        "status": "development_baseline",
        "dataset_size": int(len(dataset)),
        "categories": sorted(labels.unique().tolist()),
        "evaluation": {
            "method": "single stratified random holdout",
            "test_size": 0.5,
            "test_rows": int(len(test_labels)),
            "random_state": 42,
            "field_validated": False,
        },
        "metrics": metrics,
        "trained_at": datetime.now(UTC).isoformat(),
    }
    ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(artifact, ARTIFACT_PATH)
    return artifact


if __name__ == "__main__":
    result = train()
    print(f"Saved baseline model to {ARTIFACT_PATH}")
    print(f"Dataset rows: {result['dataset_size']}")
    print(f"Holdout rows: {result['evaluation']['test_rows']}")
    print(f"Accuracy: {result['metrics']['accuracy']:.3f}")
    print(f"Macro F1: {result['metrics']['macro_f1']:.3f}")
    print(
        "Status: development_baseline; these small-sample holdout metrics are not "
        "real-world validation."
    )
