# Kaundia — Business Overview, Business Logic & User Stories

**Organization:** উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ
(Uttar Kaundia Residential Landowners' Welfare Association, Bangladesh)

**Application type:** Member registration, approval, and dues (subscription/installment)
management system for a residential-landowners' community association. Single-locale
(Bengali) web application.

**Stack:** FastAPI + SQLAlchemy (async) + Alembic backend (`backend/`); Angular 22
standalone-component frontend (`frontend/`).

---

## 1. Business Purpose

The association needs to:

1. Let prospective members (landowners/residents in Uttar Kaundia) **submit a
   registration application** online instead of on paper.
2. Let the association's **admins/executive committee review, approve, or reject**
   applications, including verifying land ownership documents, nominees, and payment
   receipts.
3. Automatically **issue a membership ID and login credentials** to approved members.
4. Let approved **members log in** to see their profile and track their **monthly
   subscription (চাঁদা) dues** — which are due/paid per month/year.
5. Let admins **record and manage installment payments** on behalf of members.

This replaces an earlier prototype (documented in the root `README.md`) that stored
submissions in Google Sheets/Drive; that flow is legacy and superseded by the current
FastAPI + Angular + Postgres system.

---

## 2. Core Domain Entities

| Entity | Purpose | Key fields |
|---|---|---|
| **Member** | A person who has applied for or holds membership | `member_id` (e.g. `KAM-2026-0001`), `status` (PENDING / APPROVED / REJECTED), personal info (name, father/husband, mother, DOB, NID, mobile, gender, email, occupation), permanent & current address, urgent contact, payment info (admission fee, subscription, receipt no., payment method, receipt photo), photo & signature, `reviewed_by` / `reviewed_at` / `rejection_reason` |
| **Property** | Land/property owned by a member (a member may register multiple) | property type(s), khatian no., dag no. (CS/RS), holding number, land quantity, ownership type |
| **CoOwner** | Co-owner(s) of a registered property | owner name, owner phone |
| **ApplicableDoc** | Supporting document attached to a property | doc type, file path |
| **Nominee** | Beneficiary nominated by the member | name, relation, mobile, address |
| **MemberCredential** | Login credential issued to an approved member | username, password hash, `must_change_password` |
| **Installment** | A month's subscription/dues record for a member | year, month, amount, status (DUE / PAID), `paid_at` |
| **AdminUser** | Staff account managing the system | email, password hash, name, `role` (`SUPER_ADMIN`, `EXECUTIVE_COMMITTEE`, `ADMINISTRATOR`), optional `role_id` link to a **Role** |
| **Role** | A named, configurable RBAC role (seeded from the three admin tiers) | name, description, permissions (M2M) |
| **Permission** | A single grantable capability, keyed by `resource.action` | `key` (e.g. `member.manage`, `approve_membership`), resource, action, description |
| **UserPermissionOverride** | Per-user grant/revoke on top of a role's default permissions | user, permission, `granted` (true = extra grant, false = explicit revoke) |

**Relationships:**
Member 1—N Property, Property 1—N CoOwner/ApplicableDoc, Member 1—N Nominee,
Member 1—1 MemberCredential, Member 1—N Installment.
AdminUser reviews Members (`reviewed_by`) and manages Installments.
AdminUser N—1 Role, Role N—N Permission, AdminUser 1—N UserPermissionOverride.

---

## 3. Business Logic / Lifecycle Rules

### 3.1 Application lifecycle
```
[Public form] → Member(status=PENDING)
                     │
        admin reviews submission
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
   APPROVE                    REJECT
        │                         │
generate member_id           set rejection_reason
(KAM-{year}-{seq})           (member may be informed,
create MemberCredential       no login issued)
(username/password issued)
        │
Member can now log in
```

- A `member_id` is only generated on **approval**, formatted `KAM-{year}-{sequence}`.
- Approval issues a `MemberCredential`; the member's first login typically forces a
  password change (`must_change_password`).
- Rejection requires a `rejection_reason` to be recorded.
- Fine-grained, permission-based RBAC gates who can approve/reject/manage members.
  Routes are gated by **permission key** (e.g. `member.manage`, `approve_membership`,
  `manage_notices`), never by role name directly, via `require_permission(key)` — so
  permissions can be recomposed per role or per user without touching route code.
  `SUPER_ADMIN` implicitly holds every permission; `EXECUTIVE_COMMITTEE` and
  `ADMINISTRATOR` get a seeded default permission set for their tier; members get their
  own self-service permission set (`profile.*`, `property.*_own`, `membership.view_own_status`,
  etc.). A `super_admin`-only **role management** screen lets committee leadership
  reassign which permissions each role holds, and `UserPermissionOverride` allows a
  one-off grant or revoke for an individual admin on top of their role's defaults.
  Enforcement is server-side; the frontend's `permission.guard.ts` mirrors it in the UI
  only for navigation/UX, not as the source of truth.

### 3.2 Dues / installment tracking
- Each approved member accrues monthly `Installment` records (`year`, `month`,
  `amount`), each independently `DUE` or `PAID`.
- Admins mark installments as paid (`PATCH /api/admin/installments/{id}`), recording
  `paid_at`.
- Members can only view their own installment history — they cannot mark payments
  themselves (no self-service payment recording exists in the current system).

### 3.3 Authentication
- JWT access + refresh tokens; bcrypt password hashing.
- A single unified login endpoint tries admin credentials first, then member
  credentials, and returns a role-tagged token (`super_admin` | `executive_committee`
  | `administrator` | `member`) along with the caller's effective permission set, so the
  frontend can render/hide actions without a follow-up call.
- Frontend route guards mirror this: `authGuard` protects the whole authenticated
  shell; `roleGuard(ADMIN_ROLES)` further restricts admin-only routes (submissions
  review, member management); `permission.guard.ts` restricts individual routes/actions
  (e.g. role management) to callers holding a specific permission key.

---

## 4. User Stories

### Prospective member (public, unauthenticated)
- As a **prospective member**, I want to fill out a multi-step registration form
  (personal info → addresses → property list → nominees → urgent contact → payment
  info → review/confirm) so that I can apply for membership without visiting the
  association office.
- As a **prospective member**, I want to register more than one property I own under
  a single application, including co-owners and supporting documents, so that my full
  land holdings are on record.
- As a **prospective member**, I want to upload my photo, signature, and payment
  receipt so the admin has everything needed to verify my application.

### Admin / Executive Committee / Administrator
- As an **admin**, I want to see a list of all pending submissions so I can review
  new applications.
- As an **admin**, I want to open a submission's full detail (personal info,
  properties, nominees, payment) so I can verify it before deciding.
- As an **admin**, I want to **approve** a valid application, which automatically
  generates a membership ID and issues login credentials, so the applicant becomes a
  full member without manual account setup.
- As an **admin**, I want to **reject** an invalid or incomplete application with a
  reason, so the applicant/organization has a record of why it was declined.
- As an **admin**, I want to browse the full member list (not just pending
  submissions) so I can manage the existing membership base.
- As an **admin**, I want to mark a member's monthly installment as paid, so dues
  collection (often done in person/cash) is reflected in the system.
- As a **super admin**, I want certain sensitive actions restricted to higher-tier
  roles (e.g. super admin / executive committee vs. general administrator), so
  day-to-day staff cannot perform actions reserved for association leadership.
- As a **super admin**, I want to manage which permissions each role holds (and grant
  or revoke individual permissions for a specific admin), so I can adapt access to
  changes in committee structure without needing a code change.

### Approved member (authenticated)
- As a **member**, I want to log in with my issued credentials and be forced to set a
  new password on first login, so my account is secure.
- As a **member**, I want to view my dashboard summarizing my profile and dues status
  at a glance.
- As a **member**, I want to view my own profile details as submitted/approved.
- As a **member**, I want to view my installment history (which months are paid vs.
  due) so I know my payment standing with the association.
- As a **member**, I want to change my password from within the app.

---

## 5. Out of Scope / Not Currently Implemented

- No online/self-service payment gateway — payment recording is admin-driven
  (in-person collection, then marked in the system).
- No multi-language support — the app is Bengali-only by design (community-targeted,
  not internationalized).
- No member self-editing of approved application data (would require an amendment/
  re-review flow if added later).
