# Kaundia Mobile (Flutter)

Flutter port of the Angular member-registry frontend (`../frontend`), consuming the same FastAPI
backend with no backend changes. Clean Architecture, feature-first, `flutter_bloc` state
management.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=APP_FLAVOR=dev
```

Prod: `--dart-define=API_BASE_URL=https://kaundiaapi.anshintech.dpdns.org/api --dart-define=APP_FLAVOR=prod`

## Verify

```bash
flutter analyze   # must be clean
flutter test      # must be green
```

## Structure

- `lib/core/` — config, dio client + error mapping, auth/session + permissions, router guards,
  theme tokens, nav config, DI (`get_it`).
- `lib/shared/` — design-system widgets ported from the Angular web primitives; file utils
  (compress, ≤5MB guard).
- `lib/features/<area>/{data,domain,presentation}/` — DTOs/mappers/entities → BLoC → pages.
- `lib/l10n/` — ARB files (bn template, default) + generated localizations.

Read `CONVENTIONS.md` before adding code, and `ANGULAR_SOURCE_OF_TRUTH.md` to find the Angular
component a screen was ported from.
