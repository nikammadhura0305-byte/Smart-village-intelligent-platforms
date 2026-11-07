# Smart Village Intelligence API

Phase 1 provides the backend foundation: configuration, database connectivity, village/user models, JWT authentication, and a health endpoint.

## Local setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

The development default uses SQLite when `DATABASE_URL` is not set. Set `DATABASE_URL` in `.env` to use PostgreSQL.

For deployed environments, set `ENVIRONMENT=production`, use a PostgreSQL
`DATABASE_URL`, provide an explicit list of trusted `CORS_ORIGINS`, and set a
unique `SECRET_KEY` of at least 32 characters. Generate a key with
`python -c "import secrets; print(secrets.token_urlsafe(48))"` and keep it in
`backend/.env`; never commit it. Production startup rejects SQLite, wildcard
CORS origins, placeholder/short signing keys, and non-positive access-token
lifetimes. SQLite remains available for local development and tests.

- Swagger UI: http://127.0.0.1:8000/docs
- Health: http://127.0.0.1:8000/api/v1/health

## Phase 3 AI layer

Train the development classifier from the sample dataset:

```powershell
python -m app.ai.train_baseline
```

The model is a TF-IDF word and character feature pipeline with Logistic Regression. It reports held-out accuracy and macro F1, then refits on all development rows for the saved artifact. The current 24-row dataset is deliberately not production-ready; the measured metrics and low confidence values should not be presented as validated village intelligence.

The analyze endpoint includes `model_status`. The current artifact reports
`development_baseline`; the value identifies the classifier artifact and is not
a claim that its predictions have been validated in the field. On the current
24-row dataset, a reproducible stratified 50% holdout contains only 12
complaints and scored 16.7% category accuracy and 0.109 macro F1. This small
single split is diagnostic only, not evidence of real-world accuracy.

The sample dataset does not validate all analysis outputs: it has no
independent field test set, no gold priority labels, and no representative
duplicate/non-duplicate pair labels. Severity rules can be compared to the
sample labels only as a development check; affected-person counts are absent.
Department recommendations are deterministic mappings from predicted
categories, so their end-to-end accuracy depends on category accuracy.

For field validation, collect consented, de-identified and independently
annotated complaints from multiple villages, languages, and service categories.
Keep a village/time-separated test set untouched during training. Measure
category and severity per-class precision, recall, macro F1, and confusion
matrices; evaluate priority against agreed human priority labels; evaluate
duplicate detection on labeled complaint pairs using precision and recall.
Document annotator agreement and review errors with local officers before
using outputs to make operational decisions.

Analyze a complaint without creating a complaint-submission workflow:

```json
POST /ai/analyze-complaint
{
	"complaint_text": "The road near the school is damaged.",
	"language": "english",
	"affected_people": 20,
	"complaint_age_hours": 24,
	"repeated_complaints": 1,
	"location_importance": 7
}
```

The response combines the replaceable classifier, transparent severity and priority rules, TF-IDF duplicate similarity, department mapping, and evidence validation. Computer-vision inference is explicitly pending.

For a real model, collect consented complaints from multiple villages and languages, remove personal data, label category and severity with a documented annotation guide, measure inter-annotator agreement, maintain train/validation/test splits by village and time, and retrain only after evaluating macro F1, per-class precision/recall, confusion matrix, and duplicate-detection precision/recall.

## Phase 4 officer dashboard

To provision an officer directly from the command line instead of using the
registration and approval flow:

```powershell
python -m scripts.create_officer --email officer@example.com --full-name "Village Officer" --password "change-this-password" --village-name "Demo Village" --district Pune
```

For officer self-registration with administrator approval, first create an
administrator account:

```powershell
python -m scripts.create_admin --email admin@example.com --full-name "System Administrator" --password "change-this-password"
```

Officers can then register from the dashboard login page by selecting a district
and a village already registered in the database. Their account remains pending
until an administrator signs in and approves it from Settings & Profile.

To register the provided Karveer village catalog (Kolhapur district, Karvir
taluka) for officer and villager selection, run this idempotent command from
the `backend` directory:

```powershell
alembic upgrade head
python -m scripts.seed_karveer_villages
```

Apply the migration first when using an existing deployed database so its
`villages.taluka` column is available before the catalog is seeded.

Run the API and open the dashboard:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Open http://127.0.0.1:8000/dashboard/ and sign in with the officer account. To
open it on another device on the same trusted Wi-Fi, use the backend computer's
private IPv4 address instead of `127.0.0.1` (find it with `ipconfig`). The
dashboard refreshes live data automatically every 30 seconds. The dashboard is
a separate static officer client because Node/npm is not installed in the
current environment. It reads live dashboard, complaint, assignment, status,
insight, and digital-twin APIs; it does not alter the Flutter villager
application.

For Flutter running on a phone or Android emulator, point the app to the
backend computer's network address, not `localhost`:

```powershell
cd ..\mobile
flutter run --dart-define=API_BASE_URL=http://192.168.1.25:8000/api/v1 --dart-define=DEMO_MODE=false
```

Replace the example address with the backend computer's private IPv4 address.
Flutter Web uses the browser's host automatically unless `API_BASE_URL` is
provided. The local Android debug build permits HTTP for development; use
HTTPS for deployed builds. Citizen registration now requires selecting a
village already registered with the Gram Panchayat so reports are attached to
the same village record used by the officer dashboard.

The officer registration form's district and village selectors are populated from
village records in the backend database. Selecting a district lists its
registered villages. Approved officers can select a village to filter dashboard
metrics, complaint management, reports, analytics, and maps. All authenticated
officers can view and manage complaints across villages. Villagers can access
their own complaints and notifications. Assignment and status-change notifications are recorded for
the complaint owner and assigned officer; notification retrieval is private to
the authenticated user. The current notification provider records messages in
the database and does not deliver external push/SMS messages.

Digital-twin map points include their complaint's associated village and repeat-report count. Boundary distance checks use that complaint's village center and configured radius; valid coordinates outside the radius remain visible as warning markers. Complaints without an associated village are not compared against an officer or administrator's village boundary. Confirm village centers, radii, and GPS accuracy before relying on these markers for operational decisions.

Apply database changes to an existing environment before starting the API:

```powershell
alembic upgrade head
```

## Tests

```powershell
pytest
```
