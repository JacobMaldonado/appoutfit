# Clo·set — Backend Service

A stateless FastAPI service deployed on **Google Cloud Run** that powers all AI capabilities for the Clo·set app.

## Responsibilities

| Endpoint | Description |
|---|---|
| `POST /v1/metadata` | Analyse a clothing image (already in Firebase Storage) → extract structured metadata → patch Firestore wardrobe item |
| `POST /v1/suggestions` | Fetch wardrobe, ask Gemini to pick 4 outfit combos, concatenate images, generate a mannequin with BFL Flux, store result in Firestore |
| `POST /v1/batch-suggestions` | Daily all-users × all-moods suggestion job (triggered by Cloud Scheduler) |
| `GET /health` | Health-check probe for Cloud Run |

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | FastAPI 0.115 + Uvicorn |
| LLM / Vision | Gemini 2.5 Flash Lite (`google-generativeai`) |
| Image generation | BFL Flux via `api.bfl.ai` |
| Image composition | Pillow |
| Auth (Flutter → service) | Firebase ID token (`firebase-admin`) |
| Auth (Scheduler → service) | Google OIDC (`google-auth`) |
| Persistence | Firebase Admin SDK → Firestore + Storage |
| Config | `pydantic-settings` (`.env` files) |
| Tests | pytest + pytest-asyncio + pytest-cov |
| Deploy | Docker + Cloud Run |

---

## Environments

| `ENV` value | LLM / Image-gen | Firebase | Auth |
|---|---|---|---|
| `local` | Mocks | Not initialised | Skipped (all requests allowed) |
| `dev` | Gemini + BFL Flux | Real (dev project) | Firebase ID token + OIDC |
| `prod` | Gemini + BFL Flux | Real (prod project) | Firebase ID token + OIDC |

---

## Running locally

### With Docker Compose (recommended)

```bash
cd service
docker compose up --build
```

The service starts at `http://localhost:8080`. All AI calls use mock providers — no API keys needed.

### Without Docker

```bash
cd service
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.local .env
uvicorn app.main:app --reload --port 8080
```

### Test the health endpoint

```bash
curl http://localhost:8080/health
# → {"status":"ok"}
```

### Trigger metadata extraction (local, no auth needed)

```bash
curl -X POST http://localhost:8080/v1/metadata \
  -H "Authorization: Bearer mock-token" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","item_id":"item1","image_url":"https://example.com/shirt.jpg"}'
```

---

## Running tests

```bash
cd service
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest
```

Coverage report is printed automatically. The threshold is **40%** (enforced by `--cov-fail-under=40`).

---

## Environment variables

See `.env.example` for the full list. All variables are optional in `local` env.

| Variable | Required in dev/prod | Description |
|---|---|---|
| `ENV` | Yes | `local` \| `dev` \| `prod` |
| `GEMINI_API_KEY` | Yes | Google AI API key |
| `BFL_API_KEY` | Yes | Black Forest Labs API key |
| `FIREBASE_PROJECT_ID` | Yes | Firebase / GCP project ID |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Yes | Absolute path to service account JSON, or base-64-encoded JSON string |
| `BATCH_SCHEDULER_SA_EMAIL` | Yes | Cloud Scheduler service account email for OIDC verification |
| `PORT` | Injected by Cloud Run | HTTP port (default 8080) |

---

## Cloud Run deployment

```bash
# Authenticate
gcloud auth login
gcloud config set project YOUR_GCP_PROJECT_ID

# Deploy from source (Cloud Build handles the Docker build)
gcloud run deploy closet-service \
  --source service/ \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ENV=dev,FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --set-secrets \
    GEMINI_API_KEY=gemini-api-key:latest,\
    BFL_API_KEY=bfl-api-key:latest,\
    FIREBASE_SERVICE_ACCOUNT_JSON=firebase-sa-json:latest,\
    BATCH_SCHEDULER_SA_EMAIL=batch-scheduler-sa-email:latest
```

> **Note:** Store secrets in [Google Secret Manager](https://cloud.google.com/secret-manager) before deploying.
> The `--allow-unauthenticated` flag is safe here because the service validates Firebase ID tokens internally.

---

## Cloud Scheduler (daily batch)

```bash
# Create a service account for the scheduler
gcloud iam service-accounts create closet-scheduler \
  --display-name "Clo·set daily batch scheduler"

# Grant it permission to invoke Cloud Run
gcloud run services add-iam-policy-binding closet-service \
  --region us-central1 \
  --member serviceAccount:closet-scheduler@YOUR_PROJECT.iam.gserviceaccount.com \
  --role roles/run.invoker

# Schedule daily at 06:00 UTC
gcloud scheduler jobs create http closet-daily-suggestions \
  --schedule "0 6 * * *" \
  --uri https://YOUR_SERVICE_URL/v1/batch-suggestions \
  --oidc-service-account-email closet-scheduler@YOUR_PROJECT.iam.gserviceaccount.com \
  --http-method POST \
  --location us-central1
```

---

## Architecture notes

### Provider abstraction

All AI integrations implement abstract base classes:

```python
class LLMProvider(ABC):
    async def complete_structured(self, prompt: str, schema: type[T]) -> T: ...
    async def describe_image(self, image_bytes: bytes, prompt: str) -> str: ...

class ImageGenProvider(ABC):
    async def generate(self, prompt: str) -> bytes: ...
```

Switching models requires only a new provider class — no service changes.

### Suggestion pipeline

```
Firestore (wardrobe ≤100 items)
  → Gemini structured output: 4 OutfitCombination (item IDs + style note)
  → Download item images from Firebase Storage
  → Pillow: concatenate into composite JPEG
  → Gemini vision: describe composite → fashion illustration prompt
  → BFL Flux: generate mannequin PNG
  → Firebase Storage: upload mannequin
  → Firestore: write outfit documents
```

### Metadata pipeline

```
Firebase Storage (image URL)
  → Gemini vision: free-text clothing description
  → Gemini structured: ClothingMetadata (type, coverage, color, pattern, description)
  → Firestore: patch wardrobe item doc
```
