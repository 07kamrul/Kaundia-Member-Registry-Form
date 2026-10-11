# Constitution Traceability & Gap Analysis — গঠনতন্ত্র ২০২৬ (সহজ ভাষা)

Source of truth: `docs/constitution/Uttar_Kaundia_Constitution_Shohoj_Bhasha_2026.pdf` (9 chapters, ধারা ১–৯১, সংযুক্তি ১–৯).
Status legend: ✅ done · 🟡 partial · ❌ missing · ⚠ conflict. Phase: S1 = Step-1 conflict fix, P1/P2/P3 = module phases (M1–M11), — = no app surface required.
Verified against the codebase on 2026-10-11 (backend survey: 37 migrations, single alembic head `d2e4a6b8c0f2`; frontend survey: full route map; mobile: member-facing parity check).

## Numbers cross-check (prompt vs PDF)

| Claim | PDF | Verdict |
|---|---|---|
| Admission fee ৳500 | ৬৬.১ | ✔ correct |
| Subscription ৳100 up to 1 decimal + ৳20/extra decimal (`100 + (dec−1)×20`; 3 decimals = ৳140) | ৬৬.২, সংযুক্তি ২ | ✔ correct |
| Membership decision within 20 working days | ৩৬.৪ | ✔ correct |
| Complaint no. in 3 working days; first progress in 15 | ৭৯.২, সংযুক্তি ৬ | ✔ correct |
| Appeal within 30 days | ৪৩.১ | ✔ correct |
| AGM notice 15 days | ৫৯.১ | ✔ correct |
| Extraordinary meeting: ⅕ of voting members, called within 30 days | ৫৯.৩ | ✔ correct |
| Voter list ≥ 30 days before election | ৫৮.১ | ✔ correct |
| Quorum: Standing Council ⅓; EC 6 of 11 | ৬১.১–৬১.২ | ✔ correct |
| EC term 3 years (or authority-approved term) | ৪৬.২ | ✔ correct |
| EC = 11 posts | ৪৬.১, সংযুক্তি ১ | ✔ correct |

**Correction to the prompt's premise (fee "conflict"):** the subscription is **not** flat `rate × decimals` today. `app/services/fee_calculation.py` already computes a tiered amount — `base_amount` covers up to `base_threshold` decimals, each extra (fractional) decimal rounded **up** at `additional_rate` — with versioned effective-dated `fee_settings` and an admin editor at `/fee-settings`. What is actually missing vs ধারা ৬৬: formula taxonomy naming, the fractional-decimal rounding rule as an explicit recorded setting (সংযুক্তি ২ says council decides in writing), joint-owner/heir single-charge rules, flat-owner rule, multiple-plot rule, the constitution tiers seeded as a **draft version awaiting a recorded decision**, and a member-facing calculation breakdown.

## What already exists (don't rebuild — extend)

- Member registration + approval/rejection with written reason, member-ID minting (`UKAMKS-N`), credentials, registration installments, duplicate guards (`backend/app/api/routes/submissions.py`, `admin.py`).
- Versioned fee settings + tiered subscription calc + fee-types catalog (`fee_settings.py`, `fee_calculation.py`, `fee_catalog.py`), installments + payment proof verification, other-fees.
- RBAC with ~30 permission keys, role/override model, audit log via `record_audit()` (19 route files).
- Notices/events with scheduled publish; roadmap; **Resolution Book** (numbered resolutions, vote counts, attendance, minutes PDF); **Fund Transparency** ledger with approval workflow, reversal, member PDF report.
- Neighbours adjacency ranking + plot map with **consent-gated phone** at the *data* layer (`Member.show_in_neighbour_directory`, default **ON** — must flip to opt-in per ধারা ৭৬) and audited lookups.
- Plot boundary drawing with review/dispute flow; land data (dags/khatians).
- ID card modal **with QR code** already in the frontend (`id-card-modal.component.ts`) — no public verify endpoint yet.
- Mobile (Flutter) mirrors all member-facing modules above; no complaints/privacy/help-desk modules anywhere.

## Traceability matrix

### অধ্যায় ১ — পরিচিতি, আইনগত অবস্থান ও মৌলিক নীতি (ধারা ১–৬)

| Article | Requirement (short) | Status | Where it lives / gap | Proposed work | Phase | Legal sign-off? |
|---|---|---|---|---|---|---|
| ১.১–১.২ | Name, logo/sil/pad/ID approved by EC | 🟡 | Name in settings & PDF headers; logo exists; no approval record | Org-settings block (S1#4) + charter viewer | S1 | No |
| ১.৩ | No commercial/political use of name/logo | 🟡 | Nothing enforces; policy clause | Charter viewer clause; no feature | P1 | No |
| ২ | Non-political, non-profit | ✅ | Governance clause; no profit features exist | Charter viewer | P1 | No |
| ৩ | Head office Uttor Kaundia, Savar; area; branches need permission | ❌ | No org address/area settings | Org settings fields | S1 | Registration office confirms |
| ৪.১–৪.২ | 1961 Ordinance + DSS rules take precedence | ✅ | No conflicting automation | Charter viewer + compliance notes | P1 | Yes (authority) |
| ৪.৩ | Must not claim "registered" before certificate | ⚠ | No false claim today, but nothing prevents one; no status flag | `registration_status` setting + "প্রস্তাবিত" badge gate on header/footer/ID/PDF | S1 | No |
| ৫ | Motto & priorities | 🟡 | Not displayed | Charter viewer | P1 | No |
| ৬ | Prohibited acts (land trade, extortion, POA pressure, gate-blocking…) | 🟡 | No enforcement surface needed beyond audit + policy | Charter viewer; ensure no feature enables these | P1 | No |

### অধ্যায় ২ — সমাজকল্যাণ, নাগরিক সচেতনতা ও জনস্বার্থ (ধারা ৭–১৫)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৭ | Mutual welfare & social cohesion | ❌ | No welfare module | M8 welfare aid + directory | P3 | No |
| ৮ | Civic education, land-document literacy | ❌ | No knowledge centre | M2 guides (mutation, khatian, tax…) | P1 | No |
| ৯ | Help desk, general info, no forced lawyer/broker, publish service scope | ❌ | Nothing | M2 help desk + service charter (সংযুক্তি ৬) | P1 | No |
| ১০ | Health & humanitarian support; no entitlement from dues (১০.২) | ❌ | Nothing | M8 welfare fund apps (M7 fund) | P3 | No |
| ১১ | Disaster response, volunteers, never obstruct authorities (১১.২) | ❌ | Nothing | M8 volunteer registry + notices broadcast | P3 | No |
| ১২ | Environment, cleanliness, safe roads awareness | ❌ | Nothing | M8 events/workshops | P3 | No |
| ১৩ | Transport/utility coordination with govt offices | ❌ | Nothing | M2 guide + M1 complaint types | P1 | No |
| ১৪ | Coordination with DSS/land office/local govt; society never wields state power | 🟡 | Escalation logging absent | M1 escalation log (GD/land-office refs) | P1 | No |
| ১৫ | Equality; women/heirs/expat/elderly care; remote submission options | 🟡 | Registration open to all; no special-care flows | M8 special-care flags; M3 remote notes | P3 | No |

### অধ্যায় ৩ — বৈধ মালিকানা, দখল ও সম্পত্তি অধিকার সুরক্ষা (ধারা ১৬–৩৩)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ১৬ | Owner decides own property; no committee can strip title | ✅ | No appropriation feature exists | Keep; charter viewer | P1 | No |
| ১৭ | Use w/o society NOC; no blocking of lawful use | ✅ | No NOC-gate features | Keep; audit no future gates | — | No |
| ১৮ | No dealing with property without written owner consent | ⚠ | Cost splits billed admin-decided (`society_costs.py`) | Opt-in project cost-sharing with logged consent | S1 | No |
| ১৯ | No demanding deeds/stamps/signatures/POA as membership condition | ✅ | Only app-signature + doc photos collected (allowed) | M2 warning notice; keep out POA capture | P1 | No |
| ২০ | Document-safety education; society never declares final ownership | ❌ | Nothing | M2 checklist + guides with disclaimer | P1 | No |
| ২১.২ | Society holds no original deeds/keys/POA; minimal copies with purpose | 🟡 | Upload copies exist for verification only | M2/M4 notice + retention rules | P1 | No |
| ২২ | Forcible-occupation complaints; no mob action by society | ❌ | No complaint module (permission keys exist, unused) | M1 complaints + "never enforce" copy | P1 | No |
| ২৩ | Ownership-protection Support Cell (3–5 neutral), advisory only | ❌ | Nothing | M1 support-cell assignment + recusal | P1 | No |
| ২৪ | Land-cutting/soil-removal complaints & evidence help | 🟡 | Plot-boundary dispute report exists | Extend to M1 evidence vault | P1 | No |
| ২৫ | Boundary neutrality — never pick a side | 🟡 | Boundary review is neutral/records-based | M1/M10 keep-neutral policy | P1 | No |
| ২৬ | Filling/road-project caution; no financial commitment without consent | ⚠ | Cost module can commit members | S1#3 opt-in agreements (scope/cap/timeline) | S1 | No |
| ২৭ | Road/access obstruction complaints; no dues-based blocking (২৭.৩) | ❌/⚠ | No complaint type; arrears gating unaudited | M1 type + S1#5 rights audit | S1+P1 | No |
| ২৮ | No developer brokerage; disclosed interests can't vote (২৯.৩) | ✅ | No developer features | M5 COI declarations cover ২৯.৩ | P2 | No |
| ২৯ | Developer projects: each owner decides; no mass POA | 🟡 | N/A today | M4 consent records when introduced | P1 | No |
| ৩০ | Voluntary mediation, both parties consent, never forced | ❌ | Nothing | M10 mediation module | P3 | No |
| ৩১ | Multiple claimants: society declares no winner | 🟡 | Boundary disputes routed to records | M1 neutral-copy | P1 | No |
| ৩২ | Emergency risk policy; no public accusation without verification | ❌ | Nothing | M1 emergency button + publication guard | P1 | No |
| ৩৩ | Land Crime Prevention Act 2023 info, lawyer-verify disclaimer | ❌ | Nothing | M2e law-info page | P1 | Content = lawyer review |

### অধ্যায় ৪ — সদস্যপদ, অধিকার, দায়িত্ব ও আপিল (ধারা ৩৪–৪৩)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৩৪ | Eligibility: adult, lawful owner/co-owner; identity + land papers checked | 🟡 | Submission collects NID/property but no dag validation or owner-type | M3 eligibility + dag check against land data | P1 | No |
| ৩৫ | Classes: founding/general/associate/honorary; associate+honorary no vote | ⚠ | Single member class only | M3 member class enum + vote gating | P1 | No |
| ৩৬ | Application form, register, written rejection reason, 20-working-day decision | 🟡 | Form+reason+register ✅; no timer, no resubmit loop | M3 20-day timer, additional-docs loop | P1 | No |
| ৩৭ | Member rights: attend, info access, complain in writing | 🟡 | Fund transparency/ledger visible; no written-complaint channel | M1 provides channel | P1 | No |
| ৩৮ | One member = one vote regardless of plots/dues | ❌ | No voting at all | M6 votes; enforced in M9 | P2 | Yes for e-voting |
| ৩৯ | Member duties & code of conduct pledge | 🟡 | No pledge capture | M3 consent tick-boxes with version+timestamp | P1 | No |
| ৪০ | Dues via receipt/bank; dues create no land rights (৪০.১) | ✅ | Receipts/payment-proof flow exists | S1#5 arrears-rights audit | S1 | No |
| ৪১ | Fair dues; hardship waiver/instalment/deferral with approval; no forced extra levies (৪১.৩) | ❌ | No waiver mechanism | S1#1 hardship workflow | S1 | No |
| ৪২ | Termination/suspension: notice → hearing → recorded decision; no retaliation for complaints (৪২.৪) | ❌ | Only approval/rejection exists | M3 termination workflow + rights guard | P1 | No |
| ৪৩ | Appeal within 30 days to appeals committee/council | ❌ | Nothing | M3 appeal + timers engine | P1 | No |

### অধ্যায় ৫ — সংগঠন কাঠামো, ক্ষমতা ও দায়িত্ব (ধারা ৪৪–৫৬)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৪৪ | Standing Council supreme; 11-member EC runs daily work | 🟡 | `executive_committee` admin role exists, no post structure | M5 bodies + posts | P2 | Authority confirms structure |
| ৪৫ | Council powers: elect EC, approve budget/audit; can't strip property rights | ❌ | No budget approval flow | M7 budget + M5 council | P2 | No |
| ৪৬ | 11 exact posts; 3-yr term; caretaker mode after expiry | ❌ | Generic roles only | M5 posts, term expiry, caretaker mode | P2 | No |
| ৪৭ | Limits: no officer may decide eviction/occupation/fines | 🟡 | RBAC keys exist; no complaint module to mis-use | M5 profile mapping + M1 policy copy | P2 | No |
| ৪৮–৫১ | Officer duties (President…Treasurer…secretaries, executive members) | ❌ | No post↔permission mapping | M5 map to RBAC profiles | P2 | No |
| ৫২ | Non-voting administrative officer | ❌ | Nothing | M5 staff account type | P2 | No |
| ৫৩ | Sub-committees with written scope; no dues/contracts/land decisions | ❌ | Nothing | M5 sub-committees | P2 | No |
| ৫৪ | Conflict-of-interest recusal in grievance handling; no service denial for disputes | ❌ | Nothing | M1/M5 recusal engine + COI register | P1/P2 | No |
| ৫৫ | Unpaid officials; documented expense reimbursement only | 🟡 | Finance ledger has categories, no official-expense policy | M7 expense categories + policy | P2 | No |
| ৫৬ | Written resignation; vacancy handling recorded & ratified | ❌ | Nothing | M5 vacancy workflow | P2 | No |

### অধ্যায় ৬ — নির্বাচন, সভা, কোরাম ও সিদ্ধান্ত (ধারা ৫৭–৬৪)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৫৭ | Election commission from council | ❌ | Nothing | M9 (behind setting) | P3 | Yes (e-ballot) |
| ৫৮ | Voter list ≥30 days prior, correction window, frozen final; one-member-one-vote; unopposed rule | ❌ | Nothing | M9 voter list + freeze | P3 | Yes for e-vote |
| ৫৯ | AGM yearly, 15-day notice; extraordinary on ⅕ petition within 30 days | 🟡 | Notice publishing exists; no meeting types/notice rules/petition | M6 scheduler + petition tracker | P2 | No |
| ৬০ | EC meets ≥ quarterly; 3-day emergency notice; minutes record interests | 🟡 | Resolution Book records meetings/votes; no cadence reminder, no COI field | M6 reminders + COI field | P2 | No |
| ৬১ | Quorum: council ⅓; EC 6/11 (or >half if size changes); authority rule wins | ❌ | No quorum calculator | M6 quorum calculator (settings-driven) | P2 | No |
| ৬২ | Majority of voters present; president's casting vote; written resolutions | 🟡 | Resolution Book has vote counts + numbering; no casting vote, no e-signature | M6 casting vote; e-sign behind setting | P2 | Yes (e-sign) |
| ৬৩ | Special resolutions can't take private land; affected-owner notice pack | ⚠ | Nothing prevents a resolution proposing member-billed works | S1#3 consent gate on project resolutions | S1 | No |
| ৬৪ | Election disputes → commission → council/authority; minutes immutable | 🟡 | Finance has 7-day edit-window + reversal analogue | M9 complaint flow; M6 immutability | P2/P3 | No |

### অধ্যায় ৭ — চাঁদা, তহবিল, ব্যাংক, সম্পদ ও নিরীক্ষা (ধারা ৬৫–৭৪)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৬৫.১–৬৫.২ | Lawful income sources; foreign funds need permission | 🟡 | Ledger categories exist; no foreign-fund flag | M7 income-source enum + foreign flag | P2 | Yes (foreign funds) |
| ৬৫.৩ | No mandatory money for "protection"/clearance | ✅ | No such fee type | Guard in S1#1 fee catalog review | S1 | No |
| ৬৬ | Fee formula: ৳500 admission; tiered dues; council-decided rounding; joint/heir/flat/multi-plot rules; dues ≠ rights (৬৬.৪) | ⚠ | Tiered calc exists but: no formula_type taxonomy, rounding is implicit (round-up), no joint/heir single-charge, no flats rule, no draft-decision flow, no member breakdown | S1#1 full formula settings + draft version + breakdown UI | S1 | No |
| ৬৭ | Welfare/emergency fund; recorded applications; not automatic entitlement | ❌ | No fund model | M7 welfare fund + M8 applications | P2/P3 | No |
| ৬৮ | Awareness/assistance expenses from approved budget | 🟡 | Expense categories exist | M7 budget linkage | P2 | No |
| ৬৯ | Dedicated bank account; joint signatories (Treasurer + 1) | 🟡 | No bank register, no dual-auth | M7 bank register + dual authorization | P2 | No |
| ৭০ | Vouchers, approval thresholds; no loans/investment from society money | 🟡 | Approval workflow exists; no thresholds/dual-auth; no loan features (✅) | M7 thresholds in settings | P2 | No |
| ৭১ | No forced project cost participation; non-participants lose nothing | ⚠ | Cost splits billed without consent | S1#3 opt-in project agreements | S1 | No |
| ৭২ | Books + annual budget (EC drafts → council approves) | 🟡 | Ledger ✅; budget absent | M7 budget workflow | P2 | No |
| ৭৩ | Annual audit + published report; privacy in inspections | ❌ | No audit upload/publication | M7 audit + annual report publish | P2 | No |
| ৭৪ | Society asset register; big assets need council/authority approval | ❌ | Nothing | M7 asset register | P2 | Authority for disposals |

### অধ্যায় ৮ — তথ্য, অভিযোগ, স্বচ্ছতা ও নৈতিকতা (ধারা ৭৫–৮৩)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৭৫ | 12 registers + edit history | 🟡 | Scattered records exist; no register index/history | M11 records vault | P1 | No |
| ৭৬ | Personal data minimal, purpose-bound, never to brokers/developers | ⚠ | Neighbour phone consent default **ON**; audit is admin-action-only | S1#2 opt-in default + M4 privacy centre | S1 | Data-retention: lawyer |
| ৭৭ | Correct/access/delete own data; no data sales | ❌ | Nothing | M4 request workflows | P1 | Retention rules |
| ৭৮ | Complaint intake → hearing → decision → appeal; confidentiality | ❌ | Nothing | M1 | P1 | No |
| ৭৯ | SLA: ack 3 wd, progress 15 wd, delay reasons | ❌ | No working-day engine | Timers engine + M1 | P1 | No |
| ৮০ | Written COI disclosure; no vote/influence | ❌ | Nothing | M5 COI register | P2 | No |
| ৮১ | Whistleblower protection; no retaliation | ❌ | Nothing | M1 anonymous flag + no-retaliation | P1 | No |
| ৮২ | Only approved spokesperson; no unverified accusations | 🟡 | Notices gated but no spokesperson concept | M6/M5 policy + notice flag | P2 | No |
| ৮৩ | Regular aggregate public-interest summary (no private data) | 🟡 | Finance publishes notices above threshold | M7 monthly aggregate summary | P2 | No |

### অধ্যায় ৯ — আইনগত প্রতিনিধিত্ব, সংশোধন ও সমাপ্তি (ধারা ৮৪–৯১)

| Article | Requirement | Status | Where / gap | Work | Phase | Legal? |
|---|---|---|---|---|---|---|
| ৮৪ | Litigation signing by written EC decision; no party to private suits | ✅ | No litigation features | Keep | — | No |
| ৮৫ | Amendment: proposal → council vote → authority approval before effect | 🟡 | No versioned charter/amendment flow | Charter viewer versions + amendment record (M11) | P1 | Yes (authority) |
| ৮৬ | Property-rights clauses have special status; hostile amendments void | ✅ | Nothing contradicts | S1#5 rights-audit as permanent guard | S1 | No |
| ৮৭ | Annexure by-laws can't contradict constitution; approval before effect | 🟡 | Config lists exist, no draft/pending state | M11 by-law records | P1 | Depends |
| ৮৮ | Dissolution only via law/authority | ✅ | No self-dissolve feature | Keep | — | — |
| ৮৯ | Post-dissolution assets to similar welfare body | ✅ | N/A (no dissolution feature) | Charter viewer | P1 | — |
| ৯০ | Interpretation: EC explains operationally, council advises; law wins | ✅ | N/A | Charter viewer | P1 | — |
| ৯১ | Effective copy = approved + registered version | ⚠ | No registration status/version gating | S1#4 status + charter versions | S1 | Yes (authority) |

### সংযুক্তি (Annexures 1–9)

| Annexure | Requirement | Status | Work | Phase | Legal? |
|---|---|---|---|---|---|
| ১ | 11-post EC signature sheet | ❌ | M5 posts page + printable sheet | P2 | No |
| ২ | Fee table; rounding/joint/heir/flat/hardship rules in writing | ⚠ | S1#1 formula settings + recorded decisions | S1 | No |
| ৩ | Ownership-protection complaint form (typed fields, evidence, disclaimers) | ❌ | M1 digital form | P1 | No |
| ৪ | 7-step emergency safe-steps guide + 999 button | ❌ | M1 emergency screen | P1 | No |
| ৫ | Membership application + data consent text | 🟡 | Registration form exists; add versioned consent + owner type | P1 (M3) | No |
| ৬ | Service charter SLAs (20/3/15 wd, 30-day appeal) | ❌ | Timers engine + charter page | P1 | No |
| ৭ | 12 registers list | ❌ | M11 records vault | P1 | No |
| ৮ | Founders' meeting resolution & signatures template | ❌ | M11 vault + printable | P1 | No |
| ৯ | Legal sources (1961 Ordinance, DSS rules, Land Crime Act 2023/Rules 2024) + pre-registration checklist | 🟡 | Links + M11 readiness checklist | P1 | Yes |

## Cross-cutting gaps (drive the shared work)

1. **No working-day/SLA/timer engine anywhere** (backend or frontend) — needed by M1, M3, M4, M6, M9 (3/15/20 wd, 30-day, 15-day, ⅕-petition, 30-day voter list).
2. **No generic admin-editable settings store with `source_article`/`decision_ref`** — only versioned fee rows, config option lists, and non-admin env settings. Needed by the "config over code" rule for every constitutional number.
3. **Audit log is admin-action-only** — needs member-data-read events (privacy centre, neighbour lookups already do this — generalize) and immutable consent/vote/evidence records.
4. **Member class, officer posts, meeting types don't exist** in the data model.
5. **Mobile parity**: every new member-facing module (M1 complaints, M2 help desk/checklist, M4 privacy, M8 welfare, M9 voting) needs a Flutter counterpart (BLoC) per the prompt.

## Proposed execution order (after sign-off)

- **Step 1 (conflicts):** S1#1 fee formula settings + draft decision · S1#2 neighbour consent default OFF + privacy groundwork · S1#3 opt-in project cost-sharing · S1#4 `registration_status` + "প্রস্তাবিত" badge + ID-card QR public verify endpoint · S1#5 arrears-rights audit.
- **Phase 1:** M1 complaints/support cell (timers engine first) · M2 help desk/knowledge centre · M3 membership upgrade · M4 privacy centre · M11 records vault/readiness.
- **Phase 2:** M5 committees/posts/COI · M6 meetings/resolutions/petitions/quorum · M7 finance controls/welfare fund/budget/audit.
- **Phase 3:** M8 welfare & community · M9 elections (behind setting) · M10 mediation.

## Needs legal / authority sign-off before enabling (build behind settings, flag)

E-voting and e-signatures on resolutions (৫৮, ৬২); foreign donations (৬৫.২); data retention schedule (৭৬–৭৭); charter amendment effect (৮৫.২); asset disposal approvals (৭৪.২); dissolution (৮৮); EC structure/term as approved by the registration authority (৪৬); registered-status claims (৪.৩, ৯১).
