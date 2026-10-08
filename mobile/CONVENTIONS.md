# Mobile port conventions (read before writing any feature code)

Source of truth: the Angular app in `frontend/` (see `frontend/src/app/...`). Port each screen's
layout, fields, validation and states from the corresponding Angular component/template/SCSS —
adapted to mobile idioms, NOT pixel-copied web layouts. Do not change backend contracts.

## Layout
- Feature-first Clean Architecture under `lib/features/<area>/`:
  - `data/` — DTOs (snake_case JSON), remote data source (uses `ApiClient`), repository impl.
  - `domain/` — entities (camelCase), repository interface if reused, hand-written mappers
    (extension methods `toEntity()` / `toDto()`; `toEntityFromApi(Map)` style is fine).
    NO code-gen mappers for DTO<->entity; `json_serializable` allowed for DTOs only.
  - `presentation/bloc/` — BLoC/Cubit per feature (`equatable` events/states).
  - `presentation/pages/`, `presentation/widgets/`.
- NO API calls or business logic in widgets. Widgets read state + dispatch events only.
- Enums for string variants (see `lib/core/enums/enums.dart`). Never scatter raw status strings.

## Core APIs available (do not re-create)
- `sl<T>()` from `lib/core/di/injector.dart` — `ApiClient`, `AuthRepository`, `AppPreferences`,
  `SessionManager` (`.session!` gives `Session` with `.can(permissionKey)`, `.landingTier`).
- `ApiClient` (`lib/core/network/api_client.dart`): `getUri(path, query)`, `post`, `put`, `patch`,
  `delete`, `postMultipart(path, FormData)`, `putMultipart`, `downloadBytes(path)` (throws
  `ApiException`). All throw `ApiException` (`isNetwork`, `isUnauthorized`, `isValidation` with
  `.fieldErrors` snake_case map, `isBusiness` with `.businessMessage`, `isServer`).
- `AppConfig.fileUrl(rawPath)` for attachment URLs (percent-encodes Bengali segments).
- `AppPreferences`: theme/language + registration draft JSON string get/set/clear.
- l10n: `AppLocalizations.of(context)` — all Angular keys as camelCase getters
  (e.g. `registration.stepTitles.member` → `registrationStepTitlesMember`).
  Add MISSING keys to BOTH `lib/l10n/app_bn.arb` (template, Bangla) and `app_en.arb`, then run
  `flutter gen-l10n`. Bangla default. NEVER hard-code user-visible strings outside ARB.
- Router: `lib/core/router/app_router.dart` — pages already routed with `id` / `propertyId` /
  `returnUrl` params. Use `context.go('/path')`. Guards/permissions already wired in
  `lib/core/router/guards.dart`.
- Theme: `Theme.of(context)`; tokens in `lib/core/theme/app_theme.dart` (`AppColors`, `AppRadius`).

## Shared widgets (`lib/shared/widgets/widgets.dart`)
`PageHeader`, `AppCard`, `AppButton` (primary/secondary/danger/ghost), `StatusBadge`
(`StatusKind.pending/approved/rejected/neutral`), `EmptyState`, `InlineError(message, onRetry)`,
`SkeletonLoader`, `AppTabs`, `AppCheckbox` (white fill/black border/black check),
`AppDialog.confirm`, `showAppToast(context, msg, error:)`, `AppDataTableCards` (mobile
list-cards instead of wide tables). Need more shared widgets? Put them in a NEW file
`lib/shared/widgets/widgets_<area>.dart` — never edit `widgets.dart` (parallel agents).

## Every async screen must have
loading skeleton → data → `EmptyState` when list empty → `InlineError` with retry on failure.

## Multipart/files
Images: `prepareImage()` then `toMultipart()` from `lib/shared/utils/file_utils.dart`
(compress + ≤5MB guard). Docs: `prepareAnyFile` + `isAllowedDocType` (JPG/PNG/PDF ≤5MB).
Attach file bytes via `MultipartFile.fromFile` mirroring the Angular FormData field names exactly
(`payload` JSON + `member_photo` + `receipt_photo` + `doc_files[]` for registration).

## snake_case ↔ camelCase
Backend JSON is snake_case; entities are camelCase. Hand-write every field mapping and TEST it
(a past Angular bug: raw snake_case typed as camelCase). IDs become String client-side.
`is_active: 1` → bool. Bengali sentinels: ownership 'যৌথ' = joint.

## Responsive
`LayoutBuilder`: >= 600dp width → two-column form grids / tablet layouts; below → single column.
Touch targets ≥ 48dp. No overflow with Bangla text (taller glyphs) or in dark mode.

## Tests
- Bloc: `bloc_test` — happy path + each failure shape (validation field errors, business 400,
  network).
- Mappers: assert EVERY field incl. snake_case spelling (write the raw JSON literal yourself).
- Repository: mock `ApiClient` with `mocktail` (mock `getUri` etc.).
- Widget tests for critical interactions only.
Run: `flutter analyze` (must be clean) and `flutter test` (all green) before finishing.
