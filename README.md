# engg-robot-testing-framework


---
name: qa-explore
description: >
  Goal-oriented exploration of a feature — discovers flows, bugs, edge cases, and chaos
  scenarios in one pass by reasoning from the actual feature code and live app, not from
  a prescribed checklist. Covers exploration, edge cases, and chaos scenarios in one pass.
  Use when the user says /qa-explore, asks to explore a feature, find what breaks, or
  understand a feature before writing tests.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - Write
  - Edit
argument-hint: "[feature-name]"
user-invocable: true
---

# qa-explore — Goal-Oriented Feature Exploration

## Goal

Produce a complete picture of a feature: how it works, how it breaks right now, how it breaks at the edges, how it breaks under real-world chaos — and file the bugs to GitHub autonomously in the same pass. Output is read by `/qa-plan`, `/qa-verify`, and QA reviewers.

**This skill does not follow a checklist.** It reads the actual feature and reasons about what matters for *this* feature specifically. Two different features will produce two different shapes of findings — that is correct.

## Inputs

Read from these sources before and during exploration. If a path doesn't exist, skip it silently.

- **Feature code:** `../engg-vegastack-platform/src/**/[feature]/**`, `../engg-vegastack-platform/app/**/[feature]/**`
- **API / workers code:** `../engg-platform-workers/**/[feature]/**`
- **Validation schemas:** any `zod`/`yup` schemas in the feature path
- **i18n strings:** `../engg-vegastack-platform/messages/en.json` (exact error copy, labels)
- **Routes:** `../engg-vegastack-platform/app/**/page.tsx` under the feature
- **Existing exploration (if any):** `exploratory-testing/test-suites/[feature]/`
- **Live app:** `dev-platform.vegastack.com` (or `stg-platform.vegastack.com` if QA picks staging) via `playwright-cli`

## Phases

Five phases in one run. Phase 0 is always the first step. Phase 1 is sequential (needs the live app). Phases 2 and 3 run as parallel sub-agents over Phase 1's output. Phase 4 runs after all Findings are written.

### Phase 0 — Setup (prescriptive — always run, no skip)

**This phase runs every time, even if a feature was provided as an argument.**

**Step 1 — Pull latest code from both source repos (always on `develop`):**

> **Do NOT merge or close any GitHub Pull Requests.** `git pull` here only fast-forwards the local `develop` branch to match the remote — no PRs are touched.

```bash
# engg-vegastack-platform
cd ../engg-vegastack-platform
git stash --include-untracked -m "qa-explore auto-stash before pull"
git checkout develop
git pull origin develop

# engg-platform-workers
cd ../engg-platform-workers
git stash --include-untracked -m "qa-explore auto-stash before pull"
git checkout develop
git pull origin develop
```
If either pull fails, report the error and stop — do not proceed with stale code.
Stashed changes are intentionally left stashed — do not pop them automatically.

**Step 2 — Discover features:**
Scan both repos for top-level feature directories:
```bash
ls ../engg-vegastack-platform/src/features/   # platform feature modules
ls ../engg-platform-workers/src/events/       # worker event handlers (map to billing sub-features)
```
Merge the results into a deduplicated feature list. Rules:
- Include only directories (no files, no `CLAUDE.md`, no `index.ts`)
- Skip `_` prefixed dirs and Next.js group folders like `(auth)`, `(standalone)`
- Workers events all map to the `billing` feature — do not list them separately

**Step 3 — Present feature list to QA:**
Always display the full numbered feature list ordered by dependency tier (foundational → dependent), then ask QA to pick one. Do NOT proceed until QA responds.

Dependency tiers:
- **T1 — Foundation:** `auth` (no deps)
- **T2 — Core platform:** `workspace` (depends on auth), `billing` (depends on workspace)
- **T3 — Workspace features:** `projects`, `teams`, `connections` (all depend on workspace)
- **T4 — App features:** `dashboard`, `home`, `issues`, `notifications`, `favorites`, `audit-logs`, `cli` (all depend on T3 or T2)

Format exactly as (order and tier column required):

```
Available features to explore:

  #   Feature          Tier   Repo
  ────────────────────────────────────────────────
  1   auth             T1     engg-vegastack-platform
  2   workspace        T2     engg-vegastack-platform
  3   billing          T2     engg-vegastack-platform + workers
  4   projects         T3     engg-vegastack-platform
  5   teams            T3     engg-vegastack-platform
  6   connections      T3     engg-vegastack-platform
  7   dashboard        T4     engg-vegastack-platform
  8   home             T4     engg-vegastack-platform
  9   issues           T4     engg-vegastack-platform
  10  notifications    T4     engg-vegastack-platform
  11  favorites        T4     engg-vegastack-platform
  12  audit-logs       T4     engg-vegastack-platform
  13  cli              T4     engg-vegastack-platform

Which feature would you like to explore? Enter a number or name:
```

The numbers are assigned by the discovered features sorted into their tiers — if new features are discovered, insert them in their correct tier position and renumber the full list. Never sort alphabetically.

**If a feature argument was passed (e.g. `/qa-explore billing`):** still show the full tier-ordered list above, but pre-select the argument and ask QA to confirm or change it:
```
Pre-selected from argument: billing
[show full tier-ordered list above]
Proceed with "billing"? (y/n, or enter a different number)
```

**Step 4 — Suite discovery & selection (prescriptive — always run, do not skip):**

A **suite** is ONE user journey inside the selected feature (e.g. `billing/payment-flow`, `billing/subscription-flow`), never the whole feature. **One `/qa-explore` run covers exactly one suite.** Other suites stay in `draft` and require a separate `/qa-explore` run.

1. **List already-known suites for this feature.** Read `docs/rtm.md` (if it exists) and `ls exploratory-testing/test-suites/[feature]/` (if the dir exists). Capture each suite's current status from RTM (`in-progress`, `explored`, `planned`, `automated`, `verified`).

2. **Discover candidate journeys not yet explored.** Group related routes and source modules into journeys:
   ```bash
   find ../engg-vegastack-platform/app -type f -path "*/[feature]/*page.tsx"
   ls ../engg-vegastack-platform/src/features/[feature]/ 2>/dev/null
   ```
   Name each journey after what the user is *doing* (action + object), not after a page. Use route names and `messages/en.json` strings as naming hints. Examples: `payment-flow`, `subscription-flow`, `invoices`. Never invent abstract names like `billing-main`.

3. **Present the candidate suite list** in this exact format:
   ```
   Suites for feature: [feature]

     #   Suite              Status      Routes / scope (preview)
     ───────────────────────────────────────────────────────────────────
     1   payment-flow       explored    /billing, /billing/add-card
     2   subscription-flow  draft       /billing/plans, Stripe checkout
     3   invoices           (new)       /billing/invoices, /billing/invoices/:id

   Which suite would you like to explore? Enter a number or name.
   Only ONE suite per run — remaining suites stay in draft until you re-run /qa-explore.
   ```

4. **Stop and wait for QA to pick one suite.** Do NOT proceed to Phase 1 until QA responds. If QA asks for "all" or "everything", reply with: *"One suite per run. Pick one — I will leave the rest in draft and remind you at handoff."*

5. **If a suite was passed as a second argument** (e.g. `/qa-explore billing payment-flow`), still show the list above, pre-select that suite, and ask `Proceed with "payment-flow"? (y/n, or enter a different number)`. Do not auto-confirm.

6. **Record non-selected candidates as `draft` in RTM** in the next step. Do not explore them, do not write suite files for them, do not file bugs against them.

**Step 5 — Update RTM doc:**
After QA confirms the suite, append a new entry to `docs/rtm.md` (create the file if it doesn't exist):

```markdown
| [feature] | [suite — filled after exploration] | [TC count — filled after Phase 1] | [status: in-progress] | [date] |
```

The RTM doc schema (write the header once if file doesn't exist):
```markdown
# Requirements Traceability Matrix

Tracks every feature explored, the suites produced, TC count, and current coverage status. Updated automatically by `/qa-explore` and `/qa-plan`.

| Feature | Suite | TC Count | Status | Last Explored |
|---------|-------|----------|--------|---------------|
```

Allowed status values: `in-progress` · `explored` · `planned` · `automated` · `verified`

After Phase 1 completes, update the RTM row: fill in suite name and TC count, set status → `explored`.

### Phase 1 — Live exploration (agentic, scoped to the SELECTED suite only)

**Scope guard (prescriptive):** Explore only the suite QA selected in Phase 0 Step 4. Routes, elements, flows, and TCs that belong to other suites of the same feature are **out of scope** — do not open them, do not capture them, do not file bugs against them. If you find yourself inside a route that isn't in the selected suite, navigate back. The remaining suites will be covered in their own `/qa-explore` runs.

**Step 1.0 — Bootstrap live app access (Vercel SSO bypass — MANDATORY first step):**

Dev and staging URLs (`dev-platform.vegastack.com`, `stg-platform.vegastack.com`) sit behind **Vercel Deployment Protection**. A fresh `playwright-cli` browser session does NOT inherit the bypass that Playwright tests use via `playwright.config.ts`. You must seed it yourself before any other navigation, or every request will redirect to Vercel SSO.

1. Read the bypass token from `.env` (do not echo the value):
   - `TEST_ENV=dev` (default) → `VERCEL_BYPASS_TOKEN_DEV`
   - `TEST_ENV=stg` → `VERCEL_BYPASS_TOKEN_STG`

2. Read the base URL from `.env`: `BASE_URL_DEV` or `BASE_URL_STG`.

3. The **first** `playwright-cli` navigation of the session MUST use this URL form:
   ```
   <BASE_URL>/?x-vercel-protection-bypass=<TOKEN>&x-vercel-set-bypass-cookie=true
   ```
   This sets a `_vercel_jwt` cookie on the browser context. All subsequent navigations use normal URLs (no query params needed) — the cookie persists for the session.

4. Verify bypass worked: after the first navigation, the URL must NOT contain `vercel.com/sso` and the page must render the app shell (not the Vercel login screen). If it still redirects, the token is wrong or expired — that IS an infrastructure failure (see "break autonomy" rules).

5. If `.env` has no `VERCEL_BYPASS_TOKEN_<ENV>` key at all → real infra failure, ask QA.

**Do not** confuse a fixable SSO wall (token exists, just not applied) with an actual outage. The SSO wall is bypassable via the steps above; only stop if the token is missing or rejected.

Drive the app via `playwright-cli`. You decide the next action based on what you just observed. Open the selected suite's starting route, try the happy path end-to-end, then try what a real QA would try: empty submits, invalid values, navigating mid-action, refreshing, back button, concurrent actions you notice in the UI.

**Generated script (raw output) — write at end of Phase 1:**
After Phase 1, persist the `playwright-cli`-derived script to:
```
exploratory-testing/generated-scripts/[feature]/[suite]/raw-[suite].ts
```
This file is the **raw** capture — happy path + the negative paths you walked, with the exact selectors from `playwright-cli snapshot`. Rules for weaker models:
- One `test()` block per Flow in the Flows table — name it after the Flow's journey (e.g. `test('F1 — add card happy path', ...)`).
- Use the **exact** selectors from the Elements table — never paraphrase or invent.
- Do NOT add helpers, fixtures, page objects, retries, or `expect()` assertions for error copy — `/qa-execute` adds those when producing the production script.
- Top of file: a header comment with `// raw capture — do not edit by hand. Source: /qa-explore [feature] [suite]`.

If `playwright-cli` did not produce a recording (e.g. exploration was short), skip the file silently — do not fabricate one.

Stop exploring when:
- You've walked every reachable screen and state at least once.
- You've hit every validation path (success, known error paths) you can see in the code.
- New actions stop revealing new UI, new errors, or new state.

Capture as you go:
- **Flows** — chained screens (A → B → C) that form one user journey. Suite = one journey.
- **Elements** — every interactive element with its working selector (from `playwright-cli snapshot`, never guessed).
- **Draft TCs** — one per distinct scenario you verified.
- **Timing** — observed waits (network, animations).
- **State reset APIs** — any `DELETE`/`PUT` you see in the network tab that resets feature state.
- **Bugs** — anything that doesn't match what the code or i18n says should happen.

### Phase 2 — Edge-case reasoning (goal-oriented, sub-agent)

Given Phase 1 output and the feature code, reason about where the feature breaks at the edges. Don't apply a category list. Instead, for each field, element, list, and interaction from Phase 1, ask:
- What does this field *assume* about its input? Where is that assumption not enforced?
- What does this element *assume* about state? Where does the state diverge?
- What does this list/table *assume* about size, ordering, or contents?
- What happens when two of these assumptions collide?

Output only edge cases where you can point to the exact `file:line` or flow that breaks. Drop anything generic.

### Phase 3 — Chaos reasoning (goal-oriented, sub-agent, parallel with Phase 2)

Given Phase 1 output and the feature code, reason about what breaks over time, across sessions, with concurrent users, or when features interact. Ask:
- What state does this feature hold that could go stale across a session?
- What happens if two tabs, two users, or two devices hit this simultaneously?
- What happens mid-action — page reload, network drop, deploy, token expiry?
- What other features touch the same data, and what happens if they change it mid-flow?

Same rule: cite the exact `file:line` or flow. No generic scenarios.

### Phase 4 — File bugs to GitHub (example-driven + contract-first)

After Phases 1–3 finish and Findings are written, scan Findings for rows where `kind: bug`. For each, classify by confidence and file to GitHub autonomously. No QA gate.

**Confidence tiers:**

| Tier | Evidence required | Action |
|------|-------------------|--------|
| **confident** | `file:line` + exact error copy mismatch (vs `en.json`) + reproducible step from Phase 1 | File GH Issue open. Severity label. Issue Type = `Bug`. |
| **triage** | Partial evidence — source cited but either no exact copy mismatch OR reproduction unclear OR model can't fully explain why it's wrong | File GH Issue with labels `status:triage` + `needs-human-review`. Body says "AI suspects bug — needs QA verification." |
| **skip-file** | Too thin even for triage | Do NOT file. Move the row from Findings to "Considered but ruled out" with reason. |

**Repo routing:**
- Source file under `engg-vegastack-platform/` → file to `engg-vegastack-platform` repo
- Source file under `engg-platform-workers/` → file to `engg-platform-workers` repo
- Cross-repo bugs (bug crosses the frontend/worker boundary) → separate issues in each repo, linked via GH relationships (`Related to #xxx in other-repo`)

**After filing:** append the GH Issue URL and number to the Findings row (`GH Issue` column). If filing fails (API error, auth issue), mark the row `GH Issue: FAILED — [reason]` and continue — do not block other rows.

**Never auto-close** or edit existing open issues. Every run creates new issues only for Findings that don't already have a GH link in the table.

## Output Contract (strict — downstream skills parse this)

### `/qa-explore` writes to these paths only:

```
exploratory-testing/test-suites/[feature]/[suite].md   # Findings, Flows, Elements, draft TCs
exploratory-testing/generated-scripts/[feature]/[suite]/raw-[suite].ts  # raw CLI-generated script (if playwright-cli produces one)

bugs/[feature]/[suite].md                              # per-suite bug details (18-field body)
bugs/registry/[feature]/[suite].json                   # bug JSON registry
bugs/index.md                                          # consolidated bug table (append new rows)
```

**Never write to `tests/` directly.** Finalized test specs and production scripts live in `tests/` — but those are written by downstream skills only:
- `/qa-plan` → `tests/test-suites/[feature]/[suite].md` (13-column finalized specs)
- `/qa-execute` → `tests/generated-scripts/[feature]/[suite]/[suite].spec.ts` (production Playwright scripts)
- `/qa-execute` → `utils/locators/[feature]/[suite].selectors.ts`, `utils/test-data/[feature]/[suite].data.ts`

**Never create a `bugs/` directory inside `exploratory-testing/`.** Root `bugs/` is the single source of truth for all bug files.

**Read `references/output-format.md` before writing output.** It is the single source of truth for:
- Exact heading order and casing
- Schema of every table (Flows, Elements, TCs, Findings — with `Confidence` and `GH Issue` columns)
- ID conventions (`BUG-xxx`, `EC-xxx`, `XS-xxx`, `GAP-xxx`) — preserved from old skills for continuity
- ID generation scripts — Bug IDs via `scripts/next_bug_id.py`, TC IDs via `scripts/next_id.py` (never hand-roll either)
- Severity scale (`critical` / `high` / `medium` / `low`)
- Confidence tiers (`confident` / `triage` / `skip-file`) and the evidence each requires
- Source-citation rule (every Finding cites `file:line` or `Flow F#` — no exceptions)
- GH Issue body template (confident vs triage variants)
- Repo routing rules + cross-repo linking format
- Good vs shallow examples, anti-patterns to reject

Do not invent new columns, headings, IDs, or severity values. If the reference file doesn't cover a case, ask QA before improvising.

## Quality Constraints (must satisfy — otherwise output is shallow)

- Every row in **Findings** must cite `file:line` or a specific `Flow ID`. No generic findings.
- Every selector in **Elements** came from `playwright-cli snapshot` against the live app. No guessed selectors.
- Every error-copy assertion in **TCs** matches `messages/en.json` exactly. No paraphrased error text.
- **Findings** must include at least one of each kind (bug, edge-case, chaos) — or the "Considered but ruled out" section must explain why none exist for that kind.
- Suite name is a **user journey**, not a page name. `billing/payment-flow` ✅, `billing/billing-page` ❌.

## Self-Check (autonomous — measure against derivable truth, loop until closed)

**Run these checks without asking QA. Only break autonomy for the 3 real triggers below.**

### Coverage self-check (autonomous loop)

Measure what I captured against what's derivable from code. If coverage < truth, loop back into Phase 1/2/3 for the gap — do not ask QA.

ch
1. **Routes covered** — run `ls ../engg-vegastack-platform/app/**/[feature]/**/page.tsx`. Count routes. Diff against Flows table screens. Gap → re-enter Phase 1 for uncovered routes.
2. **Fields covered** — for every input in Elements table, confirm at least one TC each for: valid submit, invalid value, empty, boundary. Gap → extend draft TCs.
3. **Realistic-usage coverage** — read the feature and reason about how real users of THIS specific feature actually use it. What paths matter for *this* feature? What does a typical user do first, second, third? What fails in production for real users? Cover those. Billing reasons differently than auth, which reasons differently than projects — do not apply a generic checklist. The source code, UI copy, defaults, marketing markers, and existing fail fixtures are all hints the feature itself gives you about what matters. Extract the intelligence from the feature; don't impose a template onto it. No mathematical matrix, no prescribed list of "happy path + variation + upgrade flow" — just intelligent reasoning about *this* feature's real use.
4. **Validation paths** — grep feature code for `throw new`, `return error`, zod `.refine`, API error responses. Diff against TCs that exercise each path. Gap → extend Phase 1.
5. **Exit condition** — re-run 1-4. If two consecutive iterations produce no new gaps → done. If still finding gaps after 3 iterations → record unresolved gaps in "Considered but ruled out" with reason, do not block handoff.

### Output-quality self-check (before Phase 4)

6. Would a senior QA reject any row as generic or unverified? Fix or move to "Considered but ruled out".
7. Does every Finding cite a concrete source? Delete rows without sources.
8. Are bugs, edge cases, chaos, coverage-gaps distinguishable? Merge overlapping rows.
9. Could `/qa-plan` parse this file without guessing? Fix any heading/column drift.

### Filing-quality self-check (before handoff)

10. Every `kind: bug` row has a `Confidence` value from the allowed set?
11. Confident rows have exact error-copy mismatch AND reproducible steps? If not, downgrade to triage.
12. Every filed bug has a GH Issue URL in the Findings table? (Failed filings show `FAILED — reason`.)
13. Cross-repo bugs linked via GH relationships in both issues?

### When to break autonomy and ask QA (only these 3)

- **Infrastructure failure** — dev server unreachable, `gh auth status` fails, source repo unpullable, OR `VERCEL_BYPASS_TOKEN_<ENV>` missing/rejected in `.env`. NOTE: a Vercel SSO redirect with a *present* token is NOT infrastructure failure — apply the bypass per Phase 1 Step 1.0 and continue.
- **Intent ambiguity** — feature name maps to multiple sub-features (e.g., `billing` → billing-payment / billing-subscription / billing-invoices); ask QA which to explore
- **Safety gate** — about to file >20 bugs in one run (unusual volume — confirm before polluting GH)

Everything else: self-reason, self-measure, self-loop.

## What this skill does NOT do

- Does not write test scripts — that's `/qa-execute`.
- Does not formalize TCs into 13-column specs — that's `/qa-plan`.
- Does not run regression tests — that's `/qa-verify`.
- Does not close, edit, or comment on existing open GH Issues — only creates new ones for unfiled Findings.

## Handoff

When done, tell QA:
```
Exploration complete: [feature]/[suite]
- [N] flows, [N] TCs, [N] findings ([B] bugs / [E] edges / [C] chaos / [G] gaps)
- Bugs filed: [Bf] confident (open) · [Bt] triage (open, needs-human-review) · [Bs] skipped (too thin)
- File: exploratory-testing/test-suites/[feature]/[suite].md
- RTM updated: docs/rtm.md — [feature]/[suite] → explored ([N] TCs)
- Remaining suites in draft for [feature]: [list draft suites from RTM, or "none"]
- Next: /qa-plan [feature]  (to formalize this suite into specs)
- To explore another suite in this feature: /qa-explore [feature] [next-suite]



---
name: qa-plan
description: >
  Goal-oriented formalization of exploration output into 13-column specs and a single-journey
  execution plan. Reads only /qa-explore output — never re-reads codebase or live app.
  Covers spec generation and execution planning in one pass. Use when the user says /qa-plan,
  asks to generate specs, plan execution, or formalize exploration into runnable test design.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - Write
  - Edit
argument-hint: "[feature-name]"
user-invocable: true
---

# qa-plan — Formalize & Plan

## Goal

Turn `/qa-explore` findings into (1) formal 13-column specs per suite and (2) a single continuous execution plan that runs every TC with maximum coverage and minimum state resets. Output is read by `/qa-execute`.

**The core principle: exploration already confirmed what the app does. Every spec and plan produced here must be designed so that automated tests cannot fail due to test problems.** A test that fails because it shares state, depends on ordering, or is missing a precondition is a badly planned test — not a failing feature. The job of `/qa-plan` is to eliminate those failure causes before a single line of test code is written.

**Isolation is non-negotiable.** Every suite must be fully isolated — own workspace, own state, own preconditions via `ensure-state`. No suite may assume another suite ran first. The plan must be safe to run in parallel in any combination, in any order — tests must never fail due to shared state, ordering, or timing. If you can't isolate a suite (e.g., `auth-pwreset` vs `auth-login`), flag it explicitly as a serial-dependency exception and provide the exact `ensure-state` sequence that makes even that dependency safe.

**No re-exploration.** Exploration already captured flows, elements, TCs, error copy, and state reset APIs. This skill only organizes what's already there. If exploration data is thin or wrong, send it back to `/qa-explore` — don't compensate by reading the codebase here.

## Inputs

Read only these. If any is missing, stop and tell QA to run `/qa-explore` first.

- `exploratory-testing/test-suites/[feature]/[suite].md` — all exploration output (flows, TCs, elements, findings)
- `tests/workspace-pool-config.json` — workspace-per-suite assignments
- `utils/helpers/ensure-state.ts` — available state-guarantee functions (to pick from, not to write)

## Phases

Two phases, run sequentially. Multi-suite runs use sub-agents in parallel within each phase — one sub-agent per suite.

### Phase 1 — Spec generation (goal-oriented + contract-first)

For each suite, produce a 13-column spec. Reason from exploration output — which TCs share a Flow ID, which are permutations of the same action, which are negative paths that group naturally. Exact error copy comes from exploration (which pulled it from `messages/en.json`) — do not paraphrase.

Grouping rule: similar scenarios (all password errors, all card declines) become **ONE TC with sub-expected results**, not N separate TCs.

### Phase 2 — Execution planning (goal-oriented)

Plan ONE continuous journey per suite where each TC's precondition is the previous TC's postcondition. Every suite depends ONLY on `setup` — never on other suites (self-sufficient suites pattern). Pick `ensure-state` functions from `utils/helpers/ensure-state.ts` for `beforeAll` — don't invent new ones.

For the master plan, group suites that can run in parallel (independent workspaces, no shared state) and mark suites that must run serial (e.g., `auth-pwreset` after `auth-login`).

**Util citation rules (prescriptive — applies to every spec row):**

1. **`ensure-state` functions** — read `utils/helpers/ensure-state.ts` once at the start of Phase 2; treat that file as the closed set. For each suite's `beforeAll`:
   - If a matching function exists → cite it by **exact** exported name, no aliases, no paraphrase (e.g. `ensureFreshWorkspace()`).
   - If no function fits → write the placeholder `MISSING: ensure<DescriptiveName>()` in the cell verbatim, **do not** invent the function inline, **do not** write `TODO`, **do not** silently downgrade the precondition.
   - Every `MISSING:` marker must also be surfaced in the handoff so QA knows what to add.
2. **Locator references** — every spec row's selectors must point back to the exact Element row from `/qa-explore` (Elements table, by Label). Do not introduce new selectors; if exploration's Elements table is missing one, mark it `MISSING: selector for [label]` and send the suite back to `/qa-explore` rather than guessing.
3. **Test-data and locator util paths** — these live at `utils/test-data/[feature]/[suite].data.ts` and `utils/locators/[feature]/[suite].selectors.ts`. `/qa-plan` does **not** create or edit these files — `/qa-execute` does. Specs may *reference* the planned filenames, but must not list functions or constants that don't yet exist as if they did.

## Output Contract (strict)

Write to:

```
tests/test-suites/[feature]/[suite].md              # 13-column spec per suite
tests/test-plans/[feature].md                       # per-feature execution plan
tests/execution-plan.md                             # master plan (all features)
tests/registry/[feature]/[suite].json               # TC metadata (regenerated)
```

**Read `references/output-format.md` before writing output.** It is the single source of truth for:
- 13-column spec schema (columns, casing, allowed values per column)
- Flow Execution Map format (state reset column, parallel/serial marker)
- TC ID format (`TC-[SUITE]-[PR]-[SEQ]`, generated via `scripts/next_id.py`)
- Status lifecycle (`draft` → `pass` / `fail` / `flaky` / `block`)
- Automation flag (`automated` / `manual` / `deferred`)
- Per-feature test-plan and master-plan schemas
- Good vs shallow examples

Do not invent new columns or values. If the reference file doesn't cover a case, ask QA.

## Quality Constraints

- Every TC has a Flow ID referencing a flow from exploration. No orphan TCs.
- Every TC's Expected matches exploration's error copy verbatim (which matched `en.json`).
- Every suite's `beforeAll` uses existing `ensure-state` functions. If none fits, the cell must read `MISSING: ensure<Name>()` verbatim — never invent the function inline, never write `TODO`, never silently drop the precondition.
- Every selector cited in a spec row exists in `/qa-explore`'s Elements table. Missing selectors → `MISSING: selector for [label]` + send back to `/qa-explore` (do not guess).
- `/qa-plan` writes only to the paths in the Output Contract. It never creates or edits files under `utils/test-data/`, `utils/locators/`, or `utils/helpers/`.
- Every parallel-group in the master plan lists the isolated workspace each member uses, AND every suite's `workspaceKey` is unique within its parallel group. Cross-verify by reading each suite's `utils/test-data/[feature]/[suite].data.ts` — two suites with the same `workspaceKey` is a planning bug, not "shared by design."
- Manual TCs never sit mid-flow in a serial chain — end of flow or separate flow only.

## Self-Check (autonomous — measure against inputs, loop until closed)

**Run these checks without asking QA. Only break autonomy for the 3 triggers below.**

### Spec completeness (autonomous loop)

Measure specs against exploration output. If gaps exist, re-enter Phase 1 for the affected suite — don't ask QA.

1. **TC completeness** — every draft TC from exploration is represented in specs (same count or grouped with sub-expected). If specs have MORE TCs than exploration, invention happened — remove extras.
2. **Column completeness** — every spec row has all 13 columns filled (no nulls except `Last run`). Gap → extend Phase 1 for that row.
3. **Flow integrity** — every `Flow ID` in spec TCs exists in the suite's Flow Execution Map. Orphan Flow IDs → fix.
4. **Ensure-state reality** — every `State reset (beforeAll)` cell is a real function in `utils/helpers/ensure-state.ts`. Any `MISSING:` marker surfaces in handoff.
5. **Exit condition** — re-run 1-4. Two consecutive clean iterations → done.

### Execution plan validity

6. **Parallel safety — workspace uniqueness (HARD RULE):** every suite in the same parallel group MUST resolve to a unique `workspaceKey`. Verify by:
   - For each suite in the group, locate `utils/test-data/[feature]/[suite].data.ts` and read its `workspaceKey` value.
   - Two suites with the **same `workspaceKey` string** = collision, even if their files look isolated. They will call `ensureNoProjects()` / `ensureNoSubscriptions()` / etc. on the same backend workspace and wipe each other's state mid-run.
   - Resolution: assign each suite its own key (e.g. `proj-crud`, `proj-settings`, `proj-members` — never two suites sharing `proj-crud`), then add the key to `tests/workspace-pool-config.json`.
   - Also verify: every `workspaceKey` referenced by a suite exists as a key in `tests/workspace-pool-config.json`. Missing key → blocker. The pool file must list every active suite's workspace, with no orphan entries.
   - Collision found → split into serial OR (preferred) reassign each suite to its own key. Document the assignment in the master plan's parallel-group table.
7. **Serial dependencies** — every serial dependency (e.g., `auth-pwreset` after `auth-login`) is stated with reason. Implicit chains → make explicit.
8. **Runtime realism** — sum of per-suite estimates vs parallel-group wall-clock. Estimates >10× wall-clock → flag as unrealistic.

### When to break autonomy and ask QA (only these 3)

- **Missing ensure-state function** — spec needs `ensureSubscriptionPaused()` but it doesn't exist. Can't invent it; flag and ask QA to add to `utils/helpers/ensure-state.ts`.
- **Ambiguous grouping decision** — two suites both touch the same Stripe customer differently; unclear if they can parallel safely. Ask QA for the call.
- **Exploration output is thin** — <3 flows or <5 TCs for a non-trivial feature. Likely needs re-exploration, not planning. Send back to `/qa-explore`.

Everything else: self-reason, self-measure, self-loop.

## What this skill does NOT do

- Does not read the live app.
- Does not read source repos (exploration already did).
- Does not write Playwright scripts — that's `/qa-execute`.
- Does not create new `ensure-state` functions — flag missing ones for manual addition.

## Handoff

```
Planning complete: [feature]
- [N] suites, [M] TCs (automated: [A], manual: [Man], deferred: [D])
- Parallel groups: [G1, G2, ...]
- Files: tests/test-suites/[feature]/*, tests/test-plans/[feature].md, tests/execution-plan.md
- Next: /qa-execute [feature]
```


---
name: qa-verify
description: >
  Verify a bug fix in two phases — retest (does the fix work?) then regression (did it break
  anything else?). Triggered by GH Issue status change or manually via /qa-verify [bug-id].
  Use when a bug is marked ready-for-qa, or user says /qa-verify, retest a fix, or check
  regression after a fix.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - Write
  - Edit
argument-hint: "[bug-id]"
user-invocable: true
---

# qa-verify — Retest + Regression (chained)

## Goal

Given a bug marked "fixed" by dev, autonomously verify two things in order:
1. **Retest** — does the claimed fix actually resolve the specific bug?
2. **Regression** — did the fix break anything else?

Post results back to the GitHub Issue. Update local bug file status. Never auto-close an issue — QA or dev closes after reading the report.

**Phase 2 runs only if Phase 1 passes.** If retest fails, there's no point checking blast radius on a non-fix.

## Triggers

- **Status-driven** (preferred): `/bug-status-sync` detects GH Issue labeled `ready-for-qa` and fires `/qa-verify [bug-id]`.
- **Manual**: `/qa-verify BUG-123` or `/qa-verify gh#456`.
- **CI webhook**: merged PR with `Closes #456` can fire this — same entry point.

## Inputs

- `bugs/[feature]/[suite].md` — resolves `bug-id` → feature/suite + TCs covering the bug
- GH Issue via `gh issue view [num]` — current labels, linked PR, fix commit SHA
- Fix diff — `git -C ../engg-vegastack-platform diff [base]..[fix-sha]` and same for workers repo
- `tests/test-suites/[feature]/[suite].md` — spec for the bug's TCs
- `tests/test-plans/[feature].md` — suite layout for blast radius

## Phases

### Phase 1 — Retest (prescriptive)

Narrow, deterministic.

1. From the bug file, collect the TC IDs tagged to this bug (usually 2–5).
2. Run only those TCs: `npx playwright test --grep "TC-X|TC-Y|TC-Z"`.
3. Record result.

Outcomes:
- **All pass** → post GH comment `retest: passed`, update local bug status to `retest-passed`, continue to Phase 2.
- **Any fail** → post GH comment with failed TC IDs + output, update status to `retest-failed`, **STOP**. Do not run Phase 2.

### Phase 2 — Regression (goal-oriented)

Runs only after Phase 1 passes.

1. Read the fix diff (both repos). List files changed.
2. Reason about blast radius — for each changed file, which features depend on it?
   - Direct imports
   - Shared utilities / hooks / middleware
   - Shared types/schemas (zod changes propagate everywhere they're imported)
   - i18n keys (if `en.json` changed, every surface using that key is at risk)
3. Produce an impact map: affected suite → WHY it's at risk → TCs to re-run.
4. Run the mapped TCs.
5. Self-check: re-read the diff. Any changed file not covered by any affected suite? If yes, either explain why it's safe in the impact map or add it.

Outcomes:
- **All pass** → post GH comment `regression: clean`, update status to `verified`.
- **Any fail** → post GH comment with failed TCs + which file in the diff likely caused each, update status to `regression-failed`.

## Output Contract (strict)

```
tests/runs/
  verify-[bug-id]-[N].json               # combined retest + regression run data
tests/ai-test-reports/regression/
  [bug-id]-[N].md                        # impact map + blast-radius reasoning + results
bugs/[feature]/[suite].md                # bug entry status updated
```

GitHub side (via `gh issue comment`):
- One comment on Phase 1 completion (retest pass or fail)
- One comment on Phase 2 completion (regression clean or fail), only if Phase 1 passed

**Read `references/output-format.md` before writing output.** It is the single source of truth for:
- `verify-[bug-id]-[N].json` schema (phase results, blast-radius map, failed TCs)
- Impact map format (file → affected features → suites → TCs + reasoning)
- GH comment templates (retest-pass, retest-fail, regression-clean, regression-fail)
- Local bug status lifecycle (`ready-for-qa` → `retest-passed` → `verified` / `regression-failed`)
- Allowed status transitions

Do not invent new statuses or comment shapes.

## Quality Constraints

- Phase 1 runs only the TCs tied to the bug — not the whole suite, not related TCs. Scope discipline.
- Phase 2's impact map cites **why** each suite is at risk, with the file or symbol that connects them. No "it's related" hand-waving.
- Self-check before Phase 2 handoff: every file in the diff appears in the impact map, either as "covered by [suite]" or as "safe because [reason]".
- Every GH comment links to the run artifact file (not dumps raw output into the comment).
- Never auto-close the GH Issue. Post the result; QA/dev closes.

## Progress-based loop (same as /qa-execute)

If a TC fails in either phase, apply the same fix loop as `/qa-execute`:
- Different failure signal across attempts = progress, keep going.
- Same signal twice in a row = stop on that TC, write an AI note to `tests/ai-notes/[feature]/[suite]/`, continue with other TCs.
- One stuck TC never blocks the rest of the verification.

If a TC that was supposed to be fixed fails with the SAME error as the original bug → fix didn't work → STOP retest, post GH comment with the original-vs-current error comparison.

## Self-Check (autonomous — measure against git diff and registry, loop until closed)

**Run these checks without asking QA. Only break autonomy for the 3 triggers below.**

### Scope integrity (Phase 1)

1. **Retest scope** — ran only the TCs listed in `bugs/registry/[feature]/[suite].json` under `tcs[]` for this bug. Count TCs run = count in registry. Mismatch = scope creep → rerun narrow.

### Blast-radius coverage (autonomous loop, Phase 2)

Measure impact map against `git diff --name-only [base]..[fix-sha]` across both repos. If gap exists, extend impact map — don't ask QA.

2. **File coverage** — run `git -C ../engg-vegastack-platform diff --name-only [base]..[fix-sha]` and same for workers. Every file must appear in `impact_map[]` OR in `uncovered_files[]` with a justification. Gap → reason about the file and add to map.
3. **Signal coverage** — for each file in impact map, at least one of the 6 blast-radius signals (direct imports, shared exports, shared state, i18n keys, API contract, routing) must be cited in `reasoning`. Missing signal → re-reason that row.
4. **Suite-TC alignment** — every `tcs_to_run[]` entry points to real TCs in the specs (not invented). Orphan TC → remove or replace.
5. **Exit condition** — re-run 2-4. Two consecutive clean iterations → done.

### Output quality (before handoff)

6. Every GH comment posted with a link to the run artifact (not raw Playwright output)?
7. Local bug status updated to exactly one of the allowed values (see output-format reference)?
8. GH Issue NOT auto-closed by this skill? If it was, revert.

### When to break autonomy and ask QA (only these 3)

- **Diff is too large** — >20 files touched. Impact-map reasoning degrades; recommend full regression suite instead of blast-radius subset. Ask QA for the call.
- **Fix commit not deployed** — retest shows same signature as original bug AND dev commit SHA doesn't match fix SHA. Ask QA to confirm deployment before re-running.
- **Registry entry missing** — bug-id has no entry in `bugs/registry/[feature]/[suite].json`. Ask QA whether to create one or if this is a historical/external bug.

Everything else: self-reason, self-measure, self-loop.

## What this skill does NOT do

- Does NOT file new bugs — that's `/qa-bug-report` (if regression surfaces new failures, write them to `ai-notes/` for QA review, don't auto-file).
- Does NOT fix the code — `/qa-verify` only verifies; code fixes are a developer action.
- Does NOT close GH Issues — QA/dev closes after reading the report.
- Does NOT run responsive UI — that's `/responsive-ui-check`.

## Handoff

Phase 1 pass + Phase 2 clean:
```
Verified: [bug-id]
- Retest: [N] TCs passed
- Regression: [M] TCs across [K] suites passed — no blast radius
- GH comment posted on #[issue-num]
- Status: verified
- Next: dev/QA closes GH Issue
```

Phase 1 fail (retest failed):
```
Verify blocked: [bug-id]
- Retest: [F] of [N] TCs failed — fix did not land
- GH comment posted on #[issue-num] with failed TC details
- Status: retest-failed
- Next: dev investigates, re-attempts fix, re-labels ready-for-qa
```

Phase 1 pass + Phase 2 fail (regression):
```
Regression found: [bug-id]
- Retest: passed
- Regression: [F] of [M] TCs failed across [suite(s)] — fix broke something else
- Likely cause: [file from diff] (see impact map)
- GH comment posted on #[issue-num]
- Status: regression-failed
- Next: dev investigates regression, fixes, re-labels ready-for-qa
```




---
name: qa-execute
description: >
  Turn formal specs into running Playwright scripts, validate them, run them, and auto-fix
  non-bug failures — all autonomously, no human gates. Covers script generation, validation, and run in one pass.
  Use when the user says /qa-execute, asks to format scripts, run tests, validate, or produce
  a run report.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
  - Write
  - Edit
argument-hint: "[feature-name]"
user-invocable: true
---

# qa-execute — Format, Validate, Run

## Goal

Given `/qa-plan` output, produce production-ready Playwright scripts and a clean run result in one autonomous pass. Auto-fix failures that are test issues (selectors, timing, state drift). Do NOT auto-fix real bugs — write an AI note to `tests/ai-notes/` for QA review.

**The core principle: if `/qa-explore` confirmed a flow works on the live app, the automated test for that same flow must also pass.** Exploration already verified the app behavior. A test failure in automation is therefore always a test problem — never an app problem for flows that exploration passed. The only valid causes of automated test failure are:
1. The test is not isolated — it depends on another test's state, order, or timing.
2. The test is not self-sufficient — it is missing an `ensure-state` call in `beforeAll`.
3. The test has a code problem — wrong selector, wrong timing, wrong assertion.

If a test fails for any other reason on a flow that exploration confirmed working, the test is wrong — not the app. Fix the test, not the app.

**Every generated test must be fully isolated.** Tests run in parallel — a test must never fail because another test ran first, last, or alongside it. Every `beforeAll` uses `ensure-state` to create its own preconditions via API. Every suite uses its own workspace/Stripe customer from `workspace-pool-config.json`. No test shares mutable state with any other test. Isolation violations (shared accounts, implicit ordering, missing `ensure-state`) are Phase 2 validation blockers — fix them before running.

**Autonomous by design.** No QA approval gates between phases. If a phase fails beyond auto-fix, stop, write an AI note, and hand off to QA with a precise reason.

## Inputs

- `tests/test-suites/[feature]/[suite].md` — 13-column specs
- `tests/test-plans/[feature].md` — per-feature plan
- `tests/execution-plan.md` — master plan (parallel groups, workspaces)
- `tests/registry/[feature]/[suite].json` — TC metadata
- `exploratory-testing/generated-scripts/[feature]/[suite]/raw-[suite].ts` — raw Playwright from exploration
- `utils/helpers/ensure-state.ts` — existing state-guarantee functions
- `tests/workspace-pool-config.json` — workspace per suite
- `bugs/registry/[feature]/*.json` — open bug registry (used to apply skip tags)

If any input missing, stop and tell QA which skill to run first.

### TC eligibility — no human gate

**When `/qa-execute` is invoked, it runs autonomously with no status-gate confirmation.** Before Phase 1:

1. **Auto-promote `draft` → `pass`** for every TC where `automation: automated`. Update the spec file in-place. Do NOT promote `manual` or `deferred` TCs.
2. **Script all `automation: automated` TCs** (now `pass` after promotion). `manual` and `deferred` TCs are excluded from scripting — log them as `skipped: manual` or `skipped: deferred` in the run file.
3. **Bug-linked TCs get `test.skip()`** — see Phase 1 rule below. They ARE scripted but wrapped with skip so they don't run until the bug is fixed.

## Phases

Four phases, one autonomous run. **Phase 0 always runs first — never skip it.** Multi-feature runs use sub-agents in parallel within Phases 1–3 (one per feature).

### Phase 0 — Pre-flight checks (prescriptive — always run, no skip)

Discover all blockers before writing a single line of script. A blocker found here is 10x cheaper than one found mid-run.

**Step 1 — Scan specs for required external dependencies:**
Read all `tests/test-suites/[feature]/[suite].md` files for the target feature. Identify every external service the TCs depend on:
- **Mailosaur** — any TC that reads email (OTP, verification, invite, password reset)
- **Stripe** — any TC that uses payment/subscription/billing flows
- **Live app** — always required
- **GitHub API** — if any TC triggers webhook or integration flows
- **Slack / connections** — if any TC exercises notification or connection flows

Build a dependency map: `{ service → [TC IDs that need it] }`

**Step 2 — Check each dependency is reachable:**

```bash
# Live app
curl -s -o /dev/null -w "%{http_code}" https://dev-platform.vegastack.com

# Mailosaur (check API key is set and server is reachable)
curl -s -o /dev/null -w "%{http_code}" \
  -u "$MAILOSAUR_API_KEY:" \
  "https://mailosaur.com/api/servers"

# Stripe (check API key is set)
curl -s -o /dev/null -w "%{http_code}" \
  -u "$STRIPE_SECRET_KEY:" \
  "https://api.stripe.com/v1/customers?limit=1"
```

Read API keys from `.env` in the repo root. If a key env var is unset, treat the service as unreachable.

**Step 3 — Report dependency status and decide per TC:**

For each dependency:
- ✅ **Reachable** → TCs proceed normally
- ❌ **Unreachable / key missing** → mark all TCs that depend on it as `skipped: dependency-unavailable:[service]` in the run file. Do NOT fail the whole run — continue with TCs that don't need this service.

Print a pre-flight summary before Phase 1:
```
Pre-flight check:
  ✅ Live app      — reachable (200)
  ✅ Stripe        — reachable (API key set)
  ❌ Mailosaur     — UNREACHABLE (MAILOSAUR_API_KEY not set)
     → Skipping TCs: TC-AUTH-000-003, TC-AUTH-000-009, TC-SIGNUP-000-001 (3 TCs)
  ─────────────────────────────────────────
  Proceeding with [N] of [T] TCs. [S] skipped due to unavailable dependencies.
```

**Step 4 — Check Playwright and project setup:**
```bash
npx playwright --version          # Playwright installed?
node -e "require('./playwright.config.ts')"  # Config valid?
ls playwright/.auth/user.json     # Auth session exists?
```

- Playwright not installed → `npx playwright install` then re-check
- Auth session missing → run `npx playwright test tests/auth.setup.ts` first, then continue
- Config invalid → fix config error before proceeding

**Step 5 — Check missing ensure-state functions:**
Read `tests/test-plans/[feature].md` for any `MISSING:` markers from `/qa-plan`. For each missing function:
- TCs that require it → mark `skipped: missing-ensure-state:[function-name]`
- As a fallback, check if a direct API call can substitute inline in `beforeAll` — if yes, use it and note it in the run file as a temporary stub

Only after all 5 steps pass (or blockers are accounted for) → proceed to Phase 1.

### Phase 1 — Format scripts (example-driven + contract-first)

Generate production scripts from raw CLI code + specs:
- Page objects (two-level: high-level like `addCard()`, low-level like `fillCardholderName()`)
- Selectors file
- Test data file
- Flow-based `.spec.ts` — `test.describe.serial()` with `beforeAll` calling ensure-state

Rules:
- Selectors come from raw CLI code or exploration's Elements table. No guessed selectors.
- `beforeAll` navigates ONCE per flow. No `beforeEach` navigation. No session-reuse hacks (`if (exists) return`).
- Every page object includes `ensureCleanState()`.
- Scripts call page object methods only — never raw `page.locator()` in spec files.

#### Bug-linked TCs: always script, but wrap with `test.skip()`

Before writing each test block, check `bugs/registry/[feature]/*.json` for any entry whose `tcs` array contains the current TC ID AND whose `status` is NOT `Fixed` or `Won't fix`.

- **Open/triage bug found** → wrap the test with `test.skip('BUG-XXX: <title>', async () => { ... })`. The full test body is still written — it will run automatically once the skip is removed.
- **No open bug** → write `test(...)` normally.
- **Bug status = `Fixed` or `Won't fix`** → write `test(...)` normally (no skip).

Add a comment above each skipped test explaining why:
```typescript
// SKIPPED: BUG-AUTH-011 (medium, triage) — page refresh re-fires OTP call
// Remove skip tag after BUG-AUTH-011 is resolved and verified by /qa-verify
test.skip('TC-AUTH-000-043: page refresh during redirect fires OTP twice', async () => {
  // ... test body
});
```

Log every skipped-bug test in `runs/run-[N].json` as `status: skipped-open-bug` with `bug_ref`.

#### Bug-fix lifecycle

When `/qa-verify` resolves a bug (status → `Fixed`), it updates `bugs/registry/[feature]/*.json`. On the **next** `/qa-execute` run, the skip check above will see `Fixed` and emit `test(...)` instead of `test.skip(...)` — the TC runs automatically with no manual intervention.

### Phase 2 — Validate (prescriptive, autonomous)

Deterministic checks. If any check fails, fix the script automatically and re-run the check — do not ask QA.

1. **ESLint**: `npx eslint tests/ utils/`. Auto-fix what ESLint can (`--fix`). Remaining errors → fix manually.
2. **Project-specific checks** (each is a blocker if violated):
   - No `beforeEach` navigation in scripts.
   - No session-reuse hacks — no `if (await ...exists()) return` patterns.
   - `ensureCleanState()` present in every page object.
   - `beforeAll` uses an existing `ensure-state` function (not a hand-rolled reset).
   - Every TC ID matches `scripts/next_id.py` format.
   - No raw `page.locator()` in `.spec.ts` files.
   - No hardcoded URLs — uses `getBaseUrl()` helper.
   - **No hardcoded external-service identifiers** that the runtime owns — Mailosaur server domains, Stripe customer IDs, etc. Read the live value from the canonical source (e.g. `playwright/.auth/email-counter.json` for the active signup email, `auth.setup.ts`'s `EMAIL_DOMAIN` constant for Mailosaur domain). When a service is rotated (new Mailosaur server, new Stripe account), only one place changes. **Distinguish polling targets from account references:** an email used to poll Mailosaur must use the active server domain; an email that just identifies an already-registered account must keep the domain it was registered under, regardless of current server. Mass-replacing one for the other will break working tests.
   - **Workspace-key uniqueness (HARD RULE):** scan every `utils/test-data/[feature]/*.data.ts` for its `workspaceKey` value. If two suites in the same feature share a `workspaceKey`, that is a parallel-collision blocker — both `beforeAll` hooks will call `ensureNo*()` on the same backend workspace and wipe each other's state. Fix by assigning each suite a unique `workspaceKey` AND adding the key to `tests/workspace-pool-config.json`. Do not silently proceed — flag the collision in the run file and resolve before Phase 3.
   - **Workspace-pool completeness:** every `workspaceKey` referenced by any active suite's data file must exist as a key in `tests/workspace-pool-config.json`. Missing key → blocker. Stale keys in the pool that no suite uses → flag but not blocking.
   - **Mailosaur OTP-consumer serialization:** scan suites whose `beforeAll` or test bodies call `fetchOtpFromMailosaur()` / `clearMailosaurInbox()`. If more than one such suite exists, they must form a single serial dependency chain in `playwright.config.ts` (each depending on the previous), OR each must use a distinct sub-address (`test+suite-name@<active-domain>`) so polls filter by recipient. Parallel OTP pollers on a shared inbox race for the first message — flag and resolve.
   - **No overlapping `testMatch` patterns in `playwright.config.ts`:** for every pair of project entries, the `testMatch` regexes must not match the same spec file. A catch-all project (e.g. `testMatch: /generated-scripts\/auth\//` alongside dedicated `auth-login-flow`, `auth-signup-flow`, etc.) causes every auth spec to run twice — once under its dedicated project with proper setup/storageState, once under the catch-all without them. The catch-all run will fail (no auth state) AND race with the real run (Mailosaur/state conflicts). Detect by checking whether one project's pattern is a superset of another's; if so, delete the catch-all OR narrow its regex to exclude already-covered paths via `testIgnore`. Note: this trap typically appears with names like `auth-direct`, `chromium-all`, `everything` — comments may justify it as "for debugging without setup," but it should not be active in default runs.
   - **Helper functions that resolve runtime identifiers must read from canonical state files, not reconstruct from constants:** e.g. `getTestAccountEmail()` must read the actual email from `playwright/.auth/email-counter.json`'s `history` array (the last entry's `email` field), NOT reconstruct it via `` `test+tc${counter}@hardcoded-domain` ``. When the underlying service rotates (new Mailosaur server, new account format), the reconstruction goes stale silently and tests fail with confusing "wrong credentials" errors. Rule: if a value was *persisted* during setup, read it back from where it was persisted; never re-derive it from a template.

Fix loop is **approach-exhaustion-based, not attempt-count-based**:
- When a fix doesn't work, don't retry the same fix. Ask: **"what is a more reliable approach to solve this?"** Reason about the root cause, not the symptom.
- Example: if renaming a variable doesn't fix an ESLint import error, the more reliable approach is to check the actual module resolution — path alias config, tsconfig, package exports. Try that next.
- Only stop when you have genuinely tried every reasonable approach and none worked. "Same error twice" is not the stop condition — "no more approaches to try" is.
- Independent checks do not block each other. If one rule is stuck, fix others and proceed.
- Proceed to Phase 3 for TCs whose files passed validation. Skip TCs whose files are truly stuck after all approaches exhausted — record as `skipped: validation-stuck` in the run file.

### Phase 3 — Run + auto-fix (goal-oriented, autonomous)

**Pre-step: past-notes lookup (mandatory before the first fix attempt on any TC).**

Before reasoning about a failure from scratch, grep `tests/ai-notes/[feature]/[suite]/` for:
1. The current TC ID (exact match) — same test failed before
2. Same signal slug (e.g., `timing-stripe-iframe`) on any TC in the same suite

For each hit, read the note's **What AI tried** and **Recommendation** sections:
- Skip fix paths already tried and failed in past notes.
- Try fix paths marked "untested" or "worked in similar TC" first.
- If a past note links the failure to a real bug already filed, classify this run as the same bug and do NOT re-file.

Run tests:
```bash
npx playwright test                         # dev (default)
TEST_ENV=stg npx playwright test            # staging
npx playwright test --grep "TC-X-000-001"   # single TC
```

On failure, reason from the actual error and classify. **Default assumption: if exploration confirmed this flow works, the failure is a test problem.** Only escalate to "real bug" when the evidence is unambiguous (HTTP 500, explicit copy mismatch against `en.json`).

| Failure signal | Classification | Action |
|----------------|----------------|--------|
| `locator.click: Timeout` + element exists in snapshot | test problem — flaky selector | Re-snapshot via `playwright-cli`, update selector, re-run |
| `Timeout 30000ms exceeded. waiting for selector` + element is in DOM late | test problem — timing | Replace fixed wait with `waitForResponse` / `waitForLoadState` |
| State precondition unmet (e.g., card count = 0 when test expects ≥1) | test problem — missing ensure-state | Add the correct `ensure-state` call to `beforeAll` |
| Test fails when run in parallel but passes alone | test problem — isolation | Find the shared state; add ensure-state or assign dedicated workspace |
| Test fails on 2nd run but passes on 1st | test problem — not idempotent | `beforeAll` must reset state, not assume clean slate from prior run |
| `expect(...).toBe(...)` mismatch on user-visible copy | spec drift OR bug | Check `messages/en.json`; if copy changed → update spec; if app is wrong → **real bug** |
| HTTP 500 / unhandled exception from app | **real bug** | Do NOT fix. Capture request/response + stack. Write AI note to `tests/ai-notes/` for QA review. |
| Intermittent pass/fail across 3 runs of same TC | flaky test | Mark `status: flaky` in spec, do NOT auto-fix silently |

Re-run is **approach-exhaustion-based**:

When a TC fails, don't just retry — reason about the failure and ask: **"what is a more reliable approach?"**

The fix ladder (always walk down before stopping):
1. **Wrong selector** → re-snapshot with `playwright-cli`, use the exact selector from the live accessibility tree
2. **Selector still fails after re-snapshot** → check if element is inside an iframe, shadow DOM, or behind a dynamic load — use the right locator strategy for that context
3. **Timing issue** → replace `waitForTimeout` / fixed delays with `waitForResponse`, `waitForLoadState('networkidle')`, or `expect.poll()`
4. **Timing still fails** → check if the action triggers a navigation or a background API call — wait for the right signal, not a generic load
5. **State precondition unmet** → add the correct `ensure-state` call to `beforeAll`; if the function doesn't exist, stub it with a direct API call inline until the real function is added
6. **Isolation failure (passes alone, fails in parallel)** → find the shared resource — workspace, account, Stripe customer — and assign a dedicated one via `workspace-pool-config.json`
7. **Idempotency failure (passes on run 1, fails on run 2)** → `beforeAll` must actively reset state, not assume a clean slate; add a teardown API call or an `ensureNo*()` call at the start of `beforeAll`

Only write an AI note and move on when you have walked the full ladder and no approach fixed it. "I tried one thing and it didn't work" is not enough — reason about what a more reliable approach would be and try that.

- TCs that don't depend on the failed TC run normally — one stuck TC never blocks the rest of the run.
- Dependency check: a TC depends on a failed TC only if they share a flow AND the failed TC precedes it in the flow. All other TCs (other flows, other suites, other features) continue.

**AI notes — NOT GitHub Issues.** When a TC gets stuck or a failure looks like it might be a real bug, `/qa-execute` does NOT file to GitHub. It writes to `tests/ai-notes/` for QA to review. Only `/qa-explore` findings (which are deliberate observations with `file:line` evidence) route directly to GitHub. This separation keeps GitHub Issues clean and execute-time noise out of the bug tracker.

## Output Contract (strict)

```
tests/
  generated-scripts/[feature]/[suite]/*.spec.ts
  pages/[feature]/[suite].page.ts
  runs/run-[N].json                          # machine-readable — /qa-ship reads this
  ai-test-reports/run-[N].md                 # human-readable summary
  ai-notes/
    index.md                                 # regenerated — consolidated searchable index
    [feature]/[suite]/
      [TC-ID]-[signal-slug].md               # one note per stuck/suspicious failure
utils/
  locators/[feature]/[suite].selectors.ts
  test-data/[feature]/[suite].data.ts
```

**Read `references/output-format.md` before writing output.** It is the single source of truth for:
- Page object structure (two-level pattern)
- Selectors file format
- Test data file format
- `.spec.ts` template (serial flow, `beforeAll`, no `beforeEach` nav)
- `runs/run-[N].json` schema (fields, status values, auto-fix log format)
- `ai-test-reports/run-[N].md` schema
- **`ai-notes/[feature]/[suite]/[TC-ID]-[signal-slug].md` schema** — per-TC note format
- **`ai-notes/index.md` schema** — consolidated index, regenerated every run
- **Signal slug naming** — how to derive `timing-stripe-iframe`, `selector-stale-after-delete`, etc.

Do not invent new file shapes. If the reference doesn't cover a case, stop and ask QA before writing.

## Quality Constraints

- Every script compiles (TypeScript) and passes ESLint before Phase 3.
- Every flow's first TC navigates; subsequent TCs in same flow never re-navigate.
- Every auto-fix is logged in `runs/run-[N].json` with: TC ID, failure signal, classification, fix applied.
- Real bugs are never auto-fixed — only logged and handed off.
- Final pass rate, auto-fix count, and bug count are in the report summary.

## Self-Check (before handoff)

1. Did every `automation: automated` TC run or have an explicit skip reason (`skipped-open-bug`, `skipped: manual`, `skipped: deferred`, `skipped: dependency-unavailable`)? If any TC is missing without a reason, that is a blocker.
2. Is every auto-fix traceable — does `runs/run-[N].json` show the original failure + the fix?
3. Does every stuck TC have an AI note at `tests/ai-notes/[feature]/[suite]/` with **What AI tried**, **Why AI stopped**, and **Past notes referenced**?
4. Is `tests/ai-notes/index.md` regenerated with today's stuck TCs merged in?
5. Does the script pass ESLint + all project-specific checks?
6. Does every `test.skip()` block have a `BUG-XXX` reference comment directly above it?
7. Is every bug-linked skip also recorded in `runs/run-[N].json` as `status: skipped-open-bug`?

## What this skill does NOT do

- Does NOT run responsive UI checks — that's `/responsive-ui-check` (run separately).
- Does NOT commit or push — that's `/qa-ship`.
- Does NOT file bugs to GitHub — real bugs go to `tests/ai-notes/` for QA review; only `/qa-explore` findings route to GitHub directly.
- Does NOT flag execute-time failures as real bugs directly — they go to `tests/ai-notes/` for QA review first.
- Does NOT ask QA for decisions — autonomous.

## Handoff

On success / partial:
```
Execute complete: [feature] (status: complete | partial)
- Pass rate: [X]% ([P] pass | [F] fail | [Flaky] flaky | [T] total runnable)
- Skipped — open bug (test.skip): [N] TCs (bug refs: BUG-XXX, ...)
- Skipped — manual/deferred: [N] TCs
- Auto-fixed: [N] (selectors: [S], timing: [T], state: [St])
- Stuck — needs QA review: [N] (see tests/ai-notes/index.md)
- Run: tests/runs/run-[N].json
- Next: QA reviews tests/ai-notes/index.md → decides which stuck items to escalate
       or /qa-ship (if clean)
       Bug skips auto-clear on next /qa-execute run once bug status = Fixed



---
name: fix-issues
description: >
  Fix GitHub issue bugs with surgical precision across multiple repos (platform + workers).
  Reads issue, runs dependency checks, reads domain-specific skill, posts RCA to GitHub,
  proposes solutions with risk assessment, creates fix branch, applies fix, verifies with
  Playwright (max 2 attempts), posts evidence to GitHub, then hands off to /ship for
  review + build + commit + push + PR. Supports hotfixes during deploy freeze, cross-repo
  fixes, and manual bug descriptions. Use when developer says /fix-issues with a GH issue
  number/link or no arg to see open bugs across all project repos.
argument-hint: "[#issue-number | GH issue link | empty to list open bugs]"
user-invocable: true
disable-model-invocation: false
---

# Fix Issues

**Pick repo → list bugs → pick issue(s) → read issue → dependency checks + domain skill (parallel) → RCA to GitHub → developer confirms → propose solutions → create branch → apply fix → verify with Playwright → post evidence → `/ship`.**

Fix GitHub issue bugs from QA or developers. Evidence-based, minimal, pattern-aware fixes.

**Philosophy:** Fix exactly what was flagged — nothing more, nothing less. Every fix must use VegaStack patterns from `references/fix-patterns.md`.

**Reference files:** `references/fix-patterns.md` · `references/dependency-checks.md` · `references/solution-discovery.md` · `references/verification-guide.md`

## Multi-Repo Configuration

This skill operates across multiple repos in the VegaStack project:

| Repo | Local Path | GitHub |
|------|-----------|--------|
| **Platform** | `/Users/surendra.cv/projects/engg-vegastack-platform` | `VegaStack/engg-vegastack-platform` |
| **Workers** | `/Users/surendra.cv/projects/engg-platform-workers` | `VegaStack/engg-platform-workers` |

**When fixing:** `cd` into the correct repo directory before running git/code commands.
**Cross-repo fixes:** Some bugs span both repos (e.g., API change in platform + webhook handler in workers). Identify these early, fix in dependency order (usually workers first → platform second), and run `/ship` for each repo separately.

## Step 0 — Select Repo, Then Bug

**Always ask which repo first — never fetch issues before the developer chooses.**

### Step 0a — Repo Selection

Present repo picker:

```
Which repo do you want to fix bugs in?

| # | Repo | Description |
|---|------|-------------|
| 1 | **Platform** (engg-vegastack-platform) | Next.js app — UI, API routes, auth, billing |
| 2 | **Workers** (engg-platform-workers) | Cloudflare Workers — webhooks, cron, queue processing |
| 3 | **Both** | Show bugs from both repos |

Pick: `1`, `2`, `3`, or repo name (e.g., `platform`, `workers`, `both`)
```

**Wait for developer to pick before fetching any issues.**

### Step 0b — List Bugs (only for selected repo(s))

After developer picks repo(s), fetch bugs ONLY from the selected repo(s):

```bash
# Only run for selected repo(s)
cd <repo-path>
gh issue list --state open --json number,title,labels --jq '.[] | "\(.number)\t\(.title)\t\(.labels | map(.name) | join(", "))"'
```

Sort by: Severity (critical > high > medium > low) → Blocks others → Quick wins.
Size estimate: **S** (1-2 files) · **M** (3-5 files) · **L** (6+ files).

Present bug table for the selected repo(s):

```
### <Repo Name> (<repo-slug>)
| # | Priority | Issue | Title | Severity | Size | Why fix first |
|---|----------|-------|-------|----------|------|---------------|
```

If developer picked "both", show two separate tables.

**Recommendation** with reasoning, then prompt:

```
**Actions:**
- Pick an issue: `#252` (or `platform #252` / `workers #59` if both repos shown)
- Pick multiple: `#59, #58` → fix both (in dependency order)
- `new` → describe a bug manually (no GitHub issue needed)
- `additional details` → provide extra context before picking (screenshots, logs, repro steps)
```

### Handling special actions

- **Multiple issues:** Determine dependency order (usually workers → platform). Fix sequentially on separate branches per repo.
- **`new`:** Ask: What's wrong, Where, Error messages, Steps to reproduce. Investigate code, follow from Step 2. Create GH issue during Step 4.
- **`additional details`:** Prompt for: error logs, repro steps, screenshots/URLs, environment, hypothesis, related code. Re-present bug table after receiving details.
- **Direct `#203` or GitHub URL (skipping Step 0a):** Infer repo from URL. If ambiguous, ask: **"Which repo? (platform / workers)"** then skip to Step 1.

## Step 1 — Read Bug from GitHub Issue

**First:** `cd` into the correct repo directory, then:

`gh issue view <number>` — Extract: Root Cause, Where to Fix (file:line), Suggested Fix, Dependencies, technical evidence.

**Primary approach:** Read affected file → trace code path → cross-reference Expected vs Actual. GH Issue IS the source of truth.

**Cross-repo check:** Does the issue mention files/endpoints from the other repo? If so, flag as cross-repo fix early: "This fix spans both platform and workers — I'll fix workers first, then platform."

**Insufficient info:** Comment asking for repro steps, screenshots, console errors.
**No fix analysis:** Run full Phase 1 from `references/solution-discovery.md`.

**If developer provided `additional details` in Step 0:** Incorporate those details into the investigation — check the error messages, repro steps, and suspected files they mentioned.

## Step 2+3 — Dependency Checks + Domain Skill (parallel)

### Step 2 — Pre-Fix Dependency Check
Run ALL 8 checks from `references/dependency-checks.md`. Present results table:
- **"proceed"** → All clear
- **"wait"** → Blocker needs resolving

### Step 3 — Read Domain Skill
Map affected file → skill, read SKILL.md before writing any fix. See CLAUDE.md Skills table for full mapping. Key mappings:
- `features/billing/**` → `stripe-patterns` · `src/app/api/**` → `api-design` · `server/db/**` → `drizzle-patterns`
- **Workers:** `typescript-standards` (always) + `stripe-patterns` / `drizzle-patterns` where relevant
- If fix touches a DIFFERENT area, re-read the new skill

## Step 4 — Post RCA to GitHub Issue (BLOCKS)

**After analyzing the code, immediately post the Root Cause Analysis as a comment on the GitHub issue.** This happens BEFORE proposing any solutions — the RCA stands on its own as documentation on the issue.

### Step 4a — Analyze Root Cause (think like a developer)

**Don't blindly read every file or query every service.** Think first, then investigate with purpose:

1. **Read the issue** — understand the symptom, the data involved, the user's state
2. **Form a hypothesis** — "Based on the error `INVALID_OTP`, I think the OTP is either not stored, expired, or deleted after email verification"
3. **Read only the code that matters** — trace the specific code path the bug follows, not the entire feature. Start at the error point and work backwards
4. **Decide if external verification is needed** — only if the hypothesis can't be confirmed from code alone:

| Hypothesis points to | Then check | Env variable |
|---------------------|-----------|-------------|
| Data missing/wrong in DB (user state, OTP, session) | **DB** query | `DATABASE_URL` |
| Stale/cached value not updating (role, permissions) | **Redis** key | `REDIS_URL` |
| Payment/subscription mismatch between app and Stripe | **Stripe** API | `STRIPE_SECRET_KEY` |
| Code logic is clearly wrong (wrong conditional, missing check) | **Nothing** — code tells the story | — |

5. **Confirm or reject the hypothesis** — if confirmed, that's the root cause. If rejected, form a new hypothesis and repeat

**Rules:** Read-only by default. Write/delete only with explicit developer approval. Never query services "just to check" — have a reason. See `references/verification-guide.md` for commands and safety rules.

### Step 4b — Post RCA Comment to GitHub Issue

**Post immediately — no preview step.** The RCA is factual analysis, not a code change. Comment it directly on the issue so it's recorded:

```bash
gh issue comment <number> --body "$(cat <<'EOF'
## Root Cause Analysis

**Root Cause:** <underlying reason, not symptom>
**Category:** <Missing null check | Wrong conditional | Race condition | Missing validation | Wrong handler | State management bug | Other>
**Affected File(s):** `<file:line>`

### Technical Evidence
- <API endpoint, route, error details>
- <Data flow trace>
- <Git history context>

### Cross-Project Dependencies
- <If fix spans workers/CLI/other repos, list here>
- <If none: "No cross-project dependencies">
EOF
)"
```

### Step 4c — Developer Checkpoint

After RCA is posted, ask:

```
RCA posted to issue #<number>.

What would you like to do?
- **"proceed"** → I'll propose solutions and fix the bug
- **"stop"** → You investigate further or fix manually. RCA is already on the issue.
```

**This is the first checkpoint.** Some developers only want the RCA — the comment is already on the issue regardless of their choice.

## Step 5 — Propose Solutions (MANDATORY)

### Step 5a — Search Similar Past Fixes

Before proposing solutions, check if similar bugs were fixed before:
```bash
git log --all --oneline --grep="fix/" | grep -i "<feature-or-keyword>"
git log --all --oneline -- "<affected-file>" | head -10
```
If a past fix exists for a similar bug, reference it: "Similar fix in `abc1234` — used the same pattern." Prefer proven patterns over new approaches.

### Step 5b — Propose 2-3 Solutions

Follow `references/solution-discovery.md` and `references/fix-patterns.md`.

Present: `| # | Solution | Files | Risk | Blast Radius | Follows existing pattern? | Drawbacks |`

Include related PR/issue links from Step 2. Add recommendation with reasoning. If a similar past fix was found in 5a, note which solution follows that proven pattern. Drawbacks must be specific and concrete — explain what exactly happens, who is affected, how often.

**Cross-project:** Identify which files in which repo + fix order (workers first → platform second).
**High-risk (DB, auth, payment):** Include partial fix option — fix safe parts, follow-up issue for unsafe parts.
**Rules:** Always 2+ solutions · recommend one · include risk + drawbacks · wait for developer to pick.

### Step 5c — Impact Preview (after developer picks)

After developer picks a solution, show exactly what will change BEFORE making any changes:
```
### Impact Preview — Solution #<N>

**Files to change:**
- `<file:line>` — <what will change>

**Dependents affected:**
- `<file>` imports from `<affected-file>` — <impact: none / needs update>

**Confirm?** (y / pick different solution)
```
This lets the developer see the blast radius before any code is touched. If they see a risky dependent, they can pick a different solution.

## Step 6 — Create Branch + Apply Fix

**First:** `cd` into the correct repo directory for this fix.

**Pre-flight:** `git status` — uncommitted changes: "stash" / "commit first" / "continue anyway".

**Branch creation — ALWAYS checkout BEFORE making changes:**
- Normal: `git checkout develop && git pull origin develop && git checkout -b fix/<issue>-desc`
- Hotfix (deploy freeze + critical/high): `git checkout release/<version> && git pull && git checkout -b hotfix/<issue>-desc`

**Cross-repo fixes:** Create separate branches in each repo. Fix the dependency repo first (usually workers), verify, then fix the dependent repo (usually platform).

Apply chosen solution following domain skill patterns. No refactoring. No test file changes.

**After applying fix — quick regression check:**
```bash
pnpm typecheck && pnpm lint
```
If errors → fix them before moving to Step 7. Catch breakage early, not during `/ship`.

## Step 7 — Verify Fix Locally

**Max 2 attempts — then flag for manual intervention. Verification results go into Step 8's Fix Summary (no separate GH comment). Full details in `references/verification-guide.md`.**

**Verification priority (use first available):**

| Priority | Method | When to use |
|----------|--------|-------------|
| 1st | **Playwright** (testing repo) | Default — 90%+ of bugs |
| 2nd | **Dev server logs** | Server-side only bugs, no UI change — with developer permission |
| 3rd | **Manual developer check** | Playwright fails 2x or testing repo unavailable |

### Playwright Verification (default)

1. Ask developer for local URL (e.g., `http://localhost:3005/reset-password`)
2. `cd` to testing repo (`/Users/surendra.cv/projects/engg-vegastack-platform-testing`)
3. Run: `BASE_URL=<local-url> npx playwright test --grep "<relevant-test>" --headed`
4. Only `BASE_URL` changes — all other envs (Mailosaur, Stripe, etc.) come from testing repo's `.env`
5. If works → save evidence, proceed to Step 8
6. If fails → adjust fix, retry (max 2 attempts)
7. After 2 failures → post `## Fix Verification — Inconclusive` comment to GH issue, ask developer to verify manually

### Testing Repo — READ-ONLY

**NEVER** modify any file in the testing repo — no scripts, no test cases, no config, no `.env`. Only use its envs + Playwright CLI for running verification. All code changes happen in platform/workers repo only.

## Step 8 — Post Fix Summary to GitHub (BLOCKS)

**Single comment with everything — the only post-fix comment.** Fields: Solution chosen, Branch, Files Changed, Verification (method + steps + result + evidence), Summary (2-3 sentences for QA).

```bash
gh issue comment <number> --body "$(cat <<'EOF'
## Fix Applied

**Solution:** #<N> — <brief description>
**Branch:** `fix/<issue>-desc`

### Files Changed
- `<file-path>` — <what was done>

### Verification
- **Method:** Playwright auto-verified / Developer manually verified
- **Steps verified:** <from repro>
- **Result:** <Expected behavior confirmed — description>
- **Evidence:** [screenshot/link if available]

### Summary
<2-3 sentences for QA — what was broken, why, how the fix resolves it>
EOF
)"
```

## Step 9 — Ship or Fix Next

Prompt: `"ship"` → `/ship` (typecheck, lint, build, review, commit, push, PR) | `"platform #204"` or `"workers #63"` → next bug on new branch.

**Auto-link PR to issue (MANDATORY):** When `/ship` creates the PR, the PR body MUST include:
- `Fixes #<number>` — GitHub auto-closes the issue when PR merges
- `Related: #<number>` — for any related issues/PRs found in Step 2
Pass these to `/ship` so they're included in the PR body. Never create a fix PR without the `Fixes #` link.

**Cross-repo:** Run `/ship` for each repo separately.
**Hotfix:** After merge, cherry-pick to develop. Conflicts → fresh fix PR.

## Hotfix Flow

| Aspect | Normal | Hotfix |
|--------|--------|--------|
| Base branch | `develop` | `release/<version>` |
| Branch name | `fix/<issue>-desc` | `hotfix/<issue>-desc` |
| PR target | `develop` | `release/<version>` |
| After merge | Done | Cherry-pick to `develop` |

## Never Do

- Fix DB/auth/payment code without developer approval
- Skip dependency checks, domain skill, or solution proposal
- Skip Playwright verification — always produce evidence
- Commit directly — `/ship` handles all commits, pushes, PRs
- Swallow errors, hardcode values, or contradict domain skills
- Guess at fixes you can't reproduce — ask for more info
- Make changes on `develop` or `main` — always `fix/` or `hotfix/` branch
- Exceed 2 iterations without developer approval
- Keep session-level data — everything updates back to GitHub Issue
- Refactor, rename, or clean up code beyond the bug fix
- Use `any` type — use `unknown` and narrow
- Use `git add .` or `git add -A` — stage specific files only