# Kaundia Member Registry — Frontend

Angular (standalone components, TypeScript strict mode) frontend for the উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ member registry. This replaces the previous Next.js app at the repo root. The backend (FastAPI/Node/etc, TBD) is being built separately in `backend/` and is not part of this project.

## Setup

```bash
cd frontend
npm install
```

## Run the dev server

```bash
ng serve
```

Open `http://localhost:9091/`.

By default the app calls the API at `http://localhost:9090/api` (see `src/environments/environment.development.ts`). Update that file (and `environment.ts` for production) if your backend runs elsewhere.

## Build

```bash
ng build                              # production build
ng build --configuration development  # dev build (faster, unminified)
```

Output goes to `dist/frontend`.

## Project structure

```
src/app/
  core/
    models/         # TypeScript interfaces (registration + admin/member domain)
    services/       # AuthService, RegistrationService, AdminService, MemberService
    guards/         # adminGuard, memberGuard (functional route guards)
    interceptors/   # authInterceptor (attaches Bearer token, handles 401)
  shared/           # (reserved for cross-feature presentational components)
  features/
    public-registration/   # "/" — multi-section registration form
    admin/                 # "/admin/login", "/admin/submissions", "/admin/submissions/:id", "/admin/members"
    member/                 # "/member/login", "/member/change-password", "/member/profile", "/member/installments"
```

## Routes

| Path | Access | Purpose |
|---|---|---|
| `/` | public | Registration form + confirmation screen |
| `/admin/login` | public | Admin login |
| `/admin/submissions` | admin | Submissions dashboard with status filter |
| `/admin/submissions/:id` | admin | Submission detail, approve/reject |
| `/admin/members` | admin | Approved members + installment management |
| `/member/login` | public | Member login |
| `/member/change-password` | member | Forced when `must_change_password` is true |
| `/member/profile` | member | Read-only profile |
| `/member/installments` | member | Installment history |

## Auth

JWT access/refresh tokens are kept in `localStorage` (and mirrored in memory via Angular signals) by `AuthService`. `authInterceptor` attaches `Authorization: Bearer <token>` to every request and redirects to the correct login page on a 401. `adminGuard`/`memberGuard` check the stored role before activating protected routes.

## Notes / deviations

- Plain CSS (in `src/styles.scss` + inline styles) is used throughout — no UI component library, per spec.
- `signature_pad` (npm) draws the member signature on a `<canvas>`, mirroring the original `react-signature-canvas` behavior.
- The registration form is built with Angular Reactive Forms (`FormGroup`/`FormArray`) and split into section components (`member-info`, `address-info`, `urgent-contact`, `property-list`/`property-item`, `nominee-list`, `payment-info`, `confirmation`) under `features/public-registration/components/`.
- Node v25.8.1 is unsupported by this Angular CLI version (odd-numbered release) but `ng new`, `npm install`, and `ng build` all completed successfully with only an engine-version warning.
