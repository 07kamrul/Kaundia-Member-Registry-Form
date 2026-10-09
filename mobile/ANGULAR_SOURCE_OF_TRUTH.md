# Angular → Flutter source-of-truth map

The Angular app in `frontend/` is the behavior/design source of truth. For each Flutter screen,
read the Angular files below before changing behavior.

| Flutter page (mobile/lib/features) | Angular source |
|---|---|
| home | features/home/ |
| registration (6-step wizard) | features/public-registration/**, core/services/registration.service.ts, core/models/registration.model.ts |
| auth pages | features/auth/pages/**, core/services/auth.service.ts (ported to lib/core/auth/) |
| public notices/events | features/public-pages/{notices,events}/, core/services/content.service.ts + core/models/content.model.ts |
| dashboard | features/dashboard/, features/member/pages/dashboard/ |
| member: profile, installments, cost-shares, change-password, fund-transparency, roadmap, resolution-book, picnic-payment, property-request-form | features/member/pages/<same-name>/ |
| neighbours (প্রতিবেশী তথ্য: RS/CS toggle, owner cards, call/WhatsApp) | features/member/pages/neighbours/ + GET /api/member/neighbours (Angular page being ported in parallel) |
| management: submissions, members, installments-management, picnic-payments, fee-settings, society-costs, finance-management, payment-verifications, property-requests, roadmap-management, config-lists, notices, events | features/management/pages/<same-name>/ + core/services/{admin,config-list,content,finance,installment-payment,society-cost}.ts |
| super admin: roles, audit-log | features/management/pages/{role-management,audit-log}/ + core/services/rbac.service.ts |
| guards/permissions | core/guards/{auth,permission,role}.guard.ts → ported to lib/core/router/guards.dart + lib/core/auth/session.dart |
| theme | src/styles.scss → lib/core/theme/app_theme.dart |
| i18n | public/i18n/{bn,en}.json → lib/l10n/app_{bn,en}.arb (generated via `flutter gen-l10n`) |

API base URL: `--dart-define=API_BASE_URL=...` (default http://localhost:8000/api).
Static uploads: origin with `/api` stripped, per-segment percent-encoding (`AppConfig.fileUrl`).
