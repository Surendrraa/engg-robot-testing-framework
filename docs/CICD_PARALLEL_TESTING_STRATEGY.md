# CI/CD Strategy for Parallel Test Automation
### Playwright + Robot Framework + Pabot — A Proposal

**Prepared for:** Engineering Leadership
**Topic:** Running our automated UI tests fast and reliably in CI/CD
**Note:** Plain English. Tables and flowcharts instead of long paragraphs.

---

## 1. Executive Summary

| Item | Detail |
|---|---|
| **Problem** | Tests run one-by-one (sequential) → slow feedback |
| **Cause** | Robot Framework runs tests in a single line, one at a time |
| **Solution** | Use **Pabot** to run tests in parallel across CPU cores |
| **Tools** | Playwright (drives browser) + Robot Framework (writes tests) + Pabot (runs in parallel) |
| **Expected result** | ~50-minute run → **~15–20 minutes** (≈3–4× with 4 workers) |
| **The ask** | Approve a **self-hosted runner (8 GB / 4-core)** *or* Bitbucket **2x build (8 GB)** + a **2-week pilot** |

> **Realism note:** Parallel speedup is **sub-linear** — 4 workers does not give a
> clean 4× because of setup overhead and uneven test splits. We target a **safe
> ~3–4×**, not a best-case number. All timings below are **estimates to validate in
> the pilot**, not guarantees.

---

## 2. The Problem

| Today | Impact |
|---|---|
| ~100 tests × ~30s each, sequential | ~50 minutes per run |
| Every pull request waits that long | Slow feedback, lost focus |
| Developers skip/rush tests | Bugs slip into main |

> **Real scenario:** A developer fixes a bug at 4:45 PM. The suite takes ~50 min.
> They either wait past 5:30 PM or merge without full confidence. We want results
> **before they finish their coffee.**

*(Replace ~100 tests / ~30s with our actual suite size and average test time
before presenting — these are placeholders.)*

---

## 3. The Three Tools

| Tool | Role (plain English) | Analogy |
|---|---|---|
| **Robot Framework** | Writes and organizes tests as readable steps | The **blueprint & checklist** |
| **Playwright** | Drives the browser — clicks, types, checks the screen | The **hands** |
| **Pabot** | Runs many test groups at the same time | The **foreman** splitting work |

These three work **together**.

---

## 4. The Core Idea: Sequential vs Parallel

```
SEQUENTIAL (Robot alone)              PARALLEL (Robot + Pabot)
─────────────────────────            ─────────────────────────
Test A ──▶ Test B ──▶ Test C          Worker 1: Test A ─┐
  5s        5s        5s              Worker 2: Test B ─┼─▶ all at once
                                      Worker 3: Test C ─┘
Total = 15s                           Total ≈ 5s
```

| Mode | How | Total time |
|---|---|---|
| **Sequential** (Robot only) | One test after another | Sum of all tests |
| **Parallel** (Robot + Pabot) | Many tests at the same time | ≈ Slowest single group |

---

## 5. How Pabot Runs in Parallel

Pabot launches **N separate worker processes**. Each worker is fully independent.

```
                         ┌─────────────────────────────┐
                         │         PABOT (foreman)      │
                         │   splits the test suite      │
                         └──────────────┬──────────────┘
            ┌───────────────┬───────────┴───────┬───────────────┐
            ▼               ▼                   ▼                ▼
       ┌─────────┐     ┌─────────┐         ┌─────────┐     ┌─────────┐
       │ Worker 1│     │ Worker 2│         │ Worker 3│     │ Worker 4│
       ├─────────┤     ├─────────┤         ├─────────┤     ├─────────┤
       │ Python  │     │ Python  │         │ Python  │     │ Python  │
       │ Robot   │     │ Robot   │         │ Robot   │     │ Robot   │
       │ Browser │     │ Browser │         │ Browser │     │ Browser │
       └─────────┘     └─────────┘         └─────────┘     └─────────┘
            └───────────────┴─────────┬─────────┴───────────────┘
                                      ▼
                          ┌───────────────────────┐
                          │  Merged Report (1 set) │
                          └───────────────────────┘
```

**What is inside each worker:**

| Inside one worker | Purpose |
|---|---|
| Python interpreter | The engine Robot runs on |
| Robot Framework instance | Test runner, variables, libraries |
| Its own browser (Chromium) | Drives the UI for that worker |
| Its own log/output files | Merged into one report at the end |

| Strength | Trade-off |
|---|---|
| ✅ Strong isolation — one crash doesn't affect others | ❌ Each browser uses ~150–300 MB RAM |
| ✅ Works for any test type | ❌ More workers = more memory + CPU |
| ✅ Mature, industry-standard | |

---

## 6. RAM vs CPU (so we size CI correctly)

| Resource | What it does | Analogy | Limits… |
|---|---|---|---|
| **RAM** | Holds everything running | Desk size | **HOW MANY** workers you can hold |
| **CPU cores** | Actually does the work | Hands | **HOW MANY run at once** |

**Key facts:**

| Fact | Meaning |
|---|---|
| CPU fetches from RAM **on demand**, step by step | It never holds the whole program |
| Workers ≤ cores | True parallel — each worker gets a core |
| Workers > cores | OS **time-slices** (switches cores rapidly) — slower, wasteful |
| Browser tests mostly **wait** (page loads) | Waiting uses no CPU; that core is freed for others |

> **Real scenario:** We pick a cheap 2-core machine but run 6 workers. They fight
> over 2 cores, constantly switching. A 10-minute run takes 25. **We saved on the
> machine and lost on time.**

---

## 7. How to Size the CI Machine

> **Important Bitbucket reality first.** Where we run decides what we can control:
>
> | Option | What we control | CPU control? |
> |---|---|---|
> | **Bitbucket Cloud build** | **Memory tier only**: `size: 1x`=4 GB, `2x`=8 GB, `4x`=16 GB, `8x`=32 GB | ❌ No — vCPU is fixed by Atlassian (~4 vCPU) |
> | **Self-hosted runner** | **Full machine** — exact cores **and** RAM | ✅ Yes |
>
> So the core-based formula below applies **fully to self-hosted runners**. On
> Bitbucket Cloud, pick the **memory tier** and keep workers modest (≈3–4), since
> we can't add cores.

**Formula (self-hosted runner):**

```
Best workers = MIN(  CPU cores ,  (Total RAM − 2 GB for OS) ÷ 1.75 GB per worker  )
Then confirm CPU is not pinned at ~100% on every core during a run.
```

**Worked example — 8 GB RAM, 4 cores:**

| Limit | Calculation | Allows |
|---|---|---|
| CPU | 4 cores | ~4 workers |
| RAM | (8 − 2) ÷ 1.75 | ~3–4 workers |
| **Result** | MIN(4, 3–4) | **3–4 workers** ✅ |

**Quick reference (self-hosted):**

| Machine | Safe Pabot workers |
|---|---|
| 4 GB RAM, 2 cores | 2 |
| 8 GB RAM, 4 cores | 3–4 |
| 16 GB RAM, 8 cores | 6–8 |
| 32 GB RAM, 16 cores | 12–16 |

**Bitbucket Cloud equivalent:**

| Build size | Memory | Suggested workers |
|---|---|---|
| `2x` | 8 GB | 3–4 |
| `4x` | 16 GB | 4–6 (capped by fixed vCPU, not RAM) |

*(1.75 GB/worker is a deliberately safe figure — a headless Chromium + Python +
Robot worker is usually ~0.7–1.2 GB. Validate actual usage in the pilot.)*

---

## 8. The CI/CD Pipeline (end-to-end flow)

```
 ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌────────────┐   ┌────────────┐
 │ 1. Code    │──▶│ 2. Pull    │──▶│ 3. Smoke   │──▶│ 4. Full    │──▶│ 5. Collect │──▶│ 6. Gate &  │
 │   Push/PR  │   │   Image    │   │   Tests    │   │   Suite    │   │  & Report  │   │   Notify   │
 └────────────┘   └────────────┘   └────────────┘   │  (Pabot)   │   └────────────┘   └────────────┘
                                          │          └────────────┘
                                     fail fast in ~90s
                                     if basics broken
```

| Stage | What happens | Why |
|---|---|---|
| **1. Trigger** | Runs on every PR and merge to main; nightly full run | Catch issues early |
| **2. Provision** | Pull the **prebuilt image** (deps + Chromium baked in) | No install step (see §9) |
| **3. Smoke tests** | Tiny critical-path set first | Fail fast before spending on full run |
| **4. Full suite (Pabot)** | Split across cores (workers from §7) | The core speed-up |
| **5. Collect & Report** | Merge results into one HTML report; screenshots on fail | Easy debugging |
| **6. Gate & Notify** | Block merge on any failure; ping team | Protect main branch |

> **Install once, not per worker:** Dependencies sit on disk in **one place**.
> Workers do **not** reinstall — they load the same files into their own memory at
> runtime. One install on disk, many workers using it.

> **Real scenario:** Developer pushes a change. Smoke passes in 90s. Full suite
> runs in ~12 min across 4 workers. One test fails → merge blocked, screenshot
> attached, Slack pings the author. **Fixed before lunch; no broken code on main.**

---

## 9. Docker Image vs Bitbucket Pipeline Cache

**The question:** Should we bake everything into a **prebuilt Docker image** (build
once, reuse), or install fresh each run but use **Bitbucket's pipeline cache** to
speed it up?

The slow part of every run is **setup**: installing Python deps + Playwright
browser binaries (~150 MB). The three options:

```
A. FRESH EACH RUN          B. BITBUCKET CACHE          C. PREBUILT DOCKER IMAGE
─────────────────          ──────────────────          ───────────────────────
Pull base image            Pull base image             Pull our image
   ▼                          ▼                         (everything baked in)
pip install (slow)         Restore cache                  ▼
   ▼                          ▼                        Run tests immediately
playwright install (slow)  playwright install
   ▼                          (only if cache miss)
Run tests                     ▼
                           Run tests
```

**Per-run setup time (typical Bitbucket Pipelines numbers):**

| Step | A. Fresh each run | B. Bitbucket cache | C. Prebuilt image |
|---|---|---|---|
| Pull base image | ~15 s | ~15 s | ~40–90 s (image ~1–1.5 GB)† |
| `pip install` deps | ~40 s | ~5 s (restored) | **0 s** (baked in) |
| `playwright install chromium` | ~90 s | ~10 s (restored)* | **0 s** (baked in) |
| **Total setup per run** | **~145 s (~2.5 min)** | **~30 s** | **~40–90 s** |
| Consistency / reliability | Low | Medium (cache can miss/expire) | **High (identical every run)** |

\* Bitbucket cache can **miss** (cleared after ~1 week, or invalidated when
dependencies change), in which case Approach B falls back to the full ~145 s.
Note Bitbucket also has a per-cache size limit — a full browser cache may not
always upload, adding to its unpredictability.

† An image with the Chromium binary baked in is ~1–1.5 GB. Keep it **slim**
(chromium only, not all three browsers; slim base image) to stay near the lower
end. Bitbucket caches Docker layers between runs, so repeat pulls are faster.

**One-time cost of the Docker image (Approach C):**

| Activity | When | Time |
|---|---|---|
| Build image (deps + Chromium baked in) | Once, or when deps change | ~3–5 min |
| Push to registry | Per image build | ~1–2 min |
| Pull on each run | Every run | ~40–90 s (faster when layer-cached) |

| Approach | Strength | Weakness |
|---|---|---|
| **A. Fresh** | Simplest, always current | Slowest — wastes ~2.5 min every run |
| **B. Bitbucket cache** | Easy to enable, decent speed | Cache misses/expiry → unpredictable times |
| **C. Prebuilt image** | **Fastest + identical every run** | Must rebuild image when deps change |

### Recommendation

> ✅ **Use a prebuilt (slim) Docker image — Approach C.** Bake Python, Robot,
> Pabot, Playwright **and the Chromium binary** into one image in a registry. Pull
> it each run and start testing immediately.

**Why C wins — it's about reliability and worst-case, not shaving every second:**

| Reason | Benefit |
|---|---|
| **Best worst-case** | C is ~40–90 s every time; B drops to **~145 s on a cache miss** |
| **Deterministic** | Identical environment each run — no cache-miss / "works on my machine" surprises |
| **Version-pinned** | Same image tag = same result; easy rollback |
| No install step | Removes the ~2-min install (vs Approach A) entirely |
| Low maintenance | Rebuild only when dependencies change |

> Honest note: in the **best** case, Bitbucket cache (B, ~30 s) can pull ahead of a
> fresh image pull (C). We still choose C because its **worst case is far better
> and it is reproducible** — predictable CI beats occasionally-faster CI.

**Practical combo:** Approach **C as the default**; keep Bitbucket cache as a
**fallback** for anything not baked into the image. Use Approach A for quick
experiments only.

---

## 10. Recommended Setup

| Decision | Recommendation | Reason |
|---|---|---|
| Runner | **Self-hosted 8 GB / 4-core** (preferred) or Bitbucket **`size: 2x`** | Hardware control vs. zero-ops |
| Environment | **Prebuilt slim Docker image** (Chromium baked in) | Fast, deterministic (see §9) |
| Parallelism | **Pabot, 3–4 workers** | Matches a 4-core/8 GB budget |
| Browser | **Chromium, headless** | Fastest, lightest in CI |
| Merge gate | **Required passing build** (branch restriction) | Protect main |
| Reports | Merged HTML (`rebot`) + screenshots on fail | Fast debugging |
| Retries | **Re-run failed once** (`--rerunfailed` + `rebot --merge`) | Absorb rare flakiness |

**Scaling:** start at 3–4 workers → if still slow, move to **self-hosted 16 GB /
8-core** with **6–8 workers**, or split the suite across multiple runners.

---

## 11. Anticipated Questions

| Question | Answer |
|---|---|
| Will parallel tests interfere (shared data/login)? | Each worker is isolated. Risk is **shared server data** → use **unique test data per run** (timestamps/IDs) |
| Are parallel tests flaky? | Flakiness is **timing**, not parallelism. Use Playwright auto-waiting + **retry-once** for known-unstable tests |
| Machine cost? | One 8 GB / 4-core runner is modest vs. cost of slow feedback + escaped bugs |
| Rewrite existing tests? | **No** — Pabot runs current Robot tests as-is, grouped by suite |
| Wrong worker count? | One-line config change. Start at 4, measure, tune |
| Locked to one CI provider? | No — works on GitHub Actions, GitLab, Jenkins, etc. |
| Debug parallel-only failures? | Capture **screenshots + Playwright traces**; trace replays the browser step by step |

---

## 12. Rollout Plan

| Phase | Goal | Time |
|---|---|---|
| **1** | Pabot in CI, 4 workers, merged reports, merge gate | Week 1–2 |
| **2** | Smoke-first stage + caching + Slack notifications | Week 3 |
| **3** | Tune worker counts + add retries | Week 4 |
| **4** | Document for team, maintain | Ongoing |

---

## 13. Bottom Line

| Point | Summary |
|---|---|
| Why slow | Robot runs tests one at a time |
| Fix | **Pabot** runs them in parallel across CPU cores |
| Sizing | Workers = **MIN(cores, RAM allows)** |
| Pipeline | Push → prebuilt image → smoke → Pabot → merge report → gate → notify |
| Outcome | ~50 min → **~15–20 min** (≈3–4×), bugs caught before merge |
| **The ask** | Approve a **self-hosted 8 GB / 4-core runner** (or Bitbucket `2x`) + **2-week Phase 1** |
