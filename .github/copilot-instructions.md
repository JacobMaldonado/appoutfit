# Clo·set — Copilot Instructions

## What This Project Is

**Clo·set** is a mobile-first app that helps users discover new outfit combinations from clothes they already own.

The core problem: people buy lots of clothes but only ever wear a fraction of them because they can't visualise new combinations. Clo·set solves this by letting users build a digital wardrobe and get smart outfit suggestions tailored to their mood or dress code.

---

## Target User

- Women in their 20s–30s in the workforce
- Spend $200+ per month on clothes and related items
- Own a large wardrobe but feel like they "have nothing to wear"
- Would pay ~$10 for an app that genuinely helps them get dressed
- Use their phone as the primary device

---

## Core Goals (in priority order)

1. **Outfit suggestions** — Generate relevant combinations from the user's own wardrobe, filtered by mood/dress code. Quality and relevance matter more than quantity.
2. **Wardrobe management** — Let users catalogue their clothes quickly with minimal friction (type, color, pattern — nothing more).
3. **Favourites & history** — Save looks they love; browse what was suggested before.
4. **Monetisation readiness** — The UX and feature set should justify a ~$10 price point or subscription.

---

## What This Project Is NOT (for now)

- Not a social/sharing platform
- Not an AI image generator (no real photos of clothes yet — photo upload is on the roadmap)
- Not a shopping integration
- Not a laundry tracker or outfit calendar

---

## Current State

### `demo/`
A fully self-contained HTML demo (single `index.html`, ~62 KB, no server needed).

| Screen | Description |
|---|---|
| Splash | Onboarding / Get Started |
| Suggest | Mood picker → 4 outfit cards with SVG flat-lay previews |
| Wardrobe | 3-col grid of items; Add form with live SVG preview |
| Saved | Favourited outfits |
| History | Past suggestion sessions with ↻ Redo |

**Stack:** pure HTML + vanilla JS + inline SVG + `localStorage`. Zero dependencies.

---

## Clothing Taxonomy

Every item has exactly these four fields:

| Field | Values |
|---|---|
| `type` | `shirt` · `blouse` · `tshirt` · `tank` · `sweater` · `pants` · `jeans` · `skirt` · `shorts` · `dress` · `jumpsuit` · `jacket` · `coat` · `cardigan` · `blazer` |
| `coverage` | `top` · `bottom` · `fullbody` · `layer` *(derived from type, not user-entered)* |
| `color` | hex string |
| `pattern` | `solid` · `striped` · `floral` · `plaid` · `printed` |

Do not add new item fields without updating the taxonomy here first.

---

## Outfit Generation Rules

1. Either pick one **fullbody** item (dress / jumpsuit), **or** pair one **top** + one **bottom**.
2. Optionally add one **layer** (jacket / coat / cardigan / blazer) on top of either path.
3. Score candidates by mood relevance (type bonus + pattern bonus + color brightness for Night Out).
4. Return 4 distinct combinations per request.
5. Push every generation to history as a named batch.

---

## Moods / Dress Codes

`casual` · `work` · `brunch` · `night` · `active`

---

## Design Language — "Modern Boutique"

Design reference: `demo/stitch_smart_closet_stylist/modern_boutique/DESIGN.md`
Reference screens (PNG + HTML): `add_to_closet/`, `outfit_detail/`, `daily_suggestions/`, `digital_closet/`, `mood_selector/`

### Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#202F38` | Core text, primary actions |
| `primary-container` | `#36454F` | Charcoal — grounding weight |
| `secondary-fixed-dim` | `#ECBDA4` | Dusty Rose — active states, highlights, primary buttons fill |
| `tertiary-fixed` | `#F0E0C8` | Champagne — background fills, chip default bg |
| `surface` | `#F9F9F9` | Off-white — base background |
| `surface-container-lowest` | `#FFFFFF` | Cards and elevated containers |
| `outline-variant` | `#C3C7CB` | Subtle borders and dividers |

### Typography

- **Headlines:** Playfair Display — editorial weight, tight letter-spacing for display sizes
- **Body & UI:** Inter — functional precision, high legibility on mobile
- **Labels / chips:** Inter Medium + SemiBold, `letter-spacing: 0.05em` → luxury brand label effect

### Layout & Spacing

- **Mobile:** 4-column fluid grid, 20px side margins
- **Desktop:** 12-column fixed grid, 60px side margins, 20px gutters, max-width 1200px
- **Vertical rhythm:** `stack-xl` (40px) between major sections; `stack-md` (16px) inside components
- App shell phone frame: max-width 430px centered on desktop

### Elevation & Depth

- Cards: white surface + `box-shadow: 0px 10px 30px rgba(54,69,79,0.05)` (warm charcoal shadow)
- On hover/tap: card lifts slightly (shadow deepens, scale 1.01–1.02)
- Floating elements (FAB, modals): slightly more pronounced shadow

### Shape Language

- Buttons / inputs / small cards: `border-radius: 8px`
- Large cards / image containers: `border-radius: 24px`
- Chips / filters: fully pill-shaped (`border-radius: 9999px`), Champagne bg, Charcoal text; active = Dusty Rose bg
- Icons: thin/light line weight, rounded caps; filled only for active states (e.g., filled heart = saved)

### The Hanger Component

A thin horizontal hairline + `checkroom` icon used as a section divider or progress indicator. Gives the UI a distinctive editorial signature unique to Clo·set.

---

## Flutter App — Architecture & Standards

Flutter targets iOS and Android. All Flutter code lives under `app/`.
A future `backend/` sibling folder may be added in the same repo.

### Environments

Controlled by `--dart-define=ENV=<value>`. Config lives in `app/lib/config/`.

| Mode | Firebase | Generation API | How to run |
|---|---|---|---|
| `local` | Full in-memory mocks (no Firebase SDK) | `MockGenerationService` | `flutter run --dart-define=ENV=local` |
| `dev` | Firebase dev project | Real API (staging) | `flutter run --dart-define=ENV=dev` |
| `prod` | Firebase prod project | Real API (production) | `flutter run --dart-define=ENV=prod` |

Never hardcode environment-specific values outside the config classes.

### Code Standards

- **SOLID principles** — single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion. Every service, repository, and widget has one clear job.
- **Reusable code** — extract shared widgets, helpers, and logic into dedicated files. No copy-paste; prefer composition.
- **No dead code** — unused code must be removed before merging. Pre-commit hooks enforce this.
- **Dart style** — follow [Effective Dart](https://dart.dev/guides/language/effective-dart). Run `flutter analyze` before every commit.
- **No magic strings** — use constants or enums for route names, Firestore collection paths, storage keys, etc.
- **Dependency injection** — use `get_it`; never instantiate services inside widgets.

### Pre-commit Hooks

Install once:
```bash
pip install pre-commit
pre-commit install   # run from app/ directory
```

`.pre-commit-config.yaml` hooks:

| Hook | Equivalent | What it does |
|---|---|---|
| `flutter analyze` | flake8 | Lint + style errors |
| `dart fix --dry-run` | vulture | Flags dead code / unused imports |
| `scripts/check_coverage.sh` | pytest + coverage | Runs `flutter test --coverage`, fails if line coverage < 40% |

### Firebase Setup (dev + prod only)

| Service | Purpose |
|---|---|
| Firebase Auth | User authentication (Google, Apple, email/password) |
| Firestore | Wardrobe items, outfit history, saved outfits, user profile |
| Firebase Storage | Clothing item photos uploaded by the user |

**Firestore collection structure:**
```
users/{uid}/
  wardrobe/{itemId}      — ClothingItem documents
  outfits/{outfitId}     — Outfit documents (saved flag)
  history/{batchId}      — GenerationBatch documents (written by generation API)
```

Realtime Firestore subscriptions (`snapshots()`) are used to deliver outfit generation results.

### Generation API Contract

```
POST /generate   { userId, mood }
→ 200            { operationId }   ← only an ID, never outfit data
```

The API writes results to `users/{uid}/history/{operationId}` in Firestore.
The client listens to that document via a realtime stream — results appear automatically.

```dart
abstract class GenerationService {
  /// Returns the operationId (batchId). Results arrive via Firestore stream.
  Future<String> triggerGeneration({required String userId, required String mood});
}
```

`MockGenerationService` skips the HTTP call and writes mock outfits directly to the in-memory store.

### Firebase Security Rules

Full rules in `app/firebase/firestore.rules` and `app/firebase/storage.rules`.

Policy summary:
- All reads and writes require `request.auth != null`
- Users can only access their own data: `request.auth.uid == userId`
- Storage: same UID scope; only `image/*` content type allowed on write

### Authentication

Providers: **Google Sign-In**, **Sign in with Apple**, **Email + Password**
Flow: First launch → onboarding splash → auth screen → wardrobe setup (if empty) → home

### Build Instructions

#### Android
```bash
# Debug (emulator or device)
flutter run --dart-define=ENV=dev

# Release APK / App Bundle
flutter build apk --release --dart-define=ENV=prod
flutter build appbundle --release --dart-define=ENV=prod   # preferred for Play Store
```
Signing: place `android/keystore.jks` (gitignored) and fill `android/key.properties`:
```
storePassword=...  keyPassword=...  keyAlias=...  storeFile=../keystore.jks
```

#### iOS
```bash
# Debug on simulator
flutter run --dart-define=ENV=dev

# Debug on physical device — configure signing in Xcode first
open ios/Runner.xcworkspace

# Release IPA
flutter build ipa --release --dart-define=ENV=prod
# CI: flutter build ipa --export-options-plist=ios/ExportOptions.plist
```
Signing: set team ID and provisioning profiles in Xcode (`ios/Runner.xcodeproj`).

### Testing Standards

- Target **≥ 40% line coverage** across `app/lib/`; enforced by pre-commit and CI.
- **Unit tests** — services, repositories, outfit generation logic, config parsing.
- **Widget tests** — key screens: wardrobe list, outfit suggestion cards, auth forms.
- **Integration tests** — happy-path onboarding and generation flow.
- No broken tests may be merged. Fix or delete before opening a PR.
- Test files mirror `lib/` under `app/test/`.

---

## Coding Conventions — Demo (HTML only)

- **No build step.** All features must work as static files.
- **Vanilla JS only** — no frameworks.
- **localStorage** for all persistence. Keys: `closet_wardrobe`, `closet_outfits`, `closet_history`.
- **Single HTML file** (`demo/index.html`) with all CSS and JS inlined — Chrome `file://` blocks external file loads.
- When adding a clothing type: update `TYPE_COVERAGE`, `TYPE_LABELS`, `getSVG()`, and the Add Item `<select>`.
- Keep SVG viewBox at `0 0 60 70` for all clothing silhouettes.

---

## Roadmap Ideas (not committed)

- Real photo upload for wardrobe items (replace SVG with user image)
- Outfit calendar — plan outfits ahead for the week
- Packing list generator based on trip type and duration
- "What goes with this?" — tap a single item and see what pairs with it
- Sharing / export an outfit as an image
- Weather-aware outfit suggestions
- Backend API implementation (generation service, recommendation engine)

