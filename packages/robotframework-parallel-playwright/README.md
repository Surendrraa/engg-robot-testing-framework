# robotframework-parallel-playwright

Run Robot Framework test work **in parallel** inside a **single shared Playwright
browser** — many isolated contexts instead of many browser processes — **without
Pabot** and without the per-process RAM cost.

## The problem it solves

Robot Framework's test scheduler is single-threaded and sequential. The usual way
to parallelize is [Pabot](https://github.com/mkorpela/pabot), which launches **N
separate `robot` subprocesses** — and each subprocess starts its **own browser
process**. Ten parallel workers means ten Chromium processes and a large RAM bill.

This library takes a different route. You write your test flows as small **async
scenario coroutines**, and one Robot keyword runs them together with
`asyncio.gather` across many isolated **browser contexts that share one Chromium
process**.

| Model | Processes for 10 parallel | RAM |
|-------|---------------------------|-----|
| Pabot, 10 workers | 10 `robot` + **10 Chromium** | very high |
| This library, 10 parallel | 1 `robot` + **1 Chromium**, 10 contexts | low |

A `BrowserContext` is a fully isolated session (separate cookies, storage, cache)
but costs only a few MB, versus ~150–300 MB for a full browser process.

## Install

```bash
pip install robotframework-parallel-playwright
python -m playwright install chromium
```

## Quick start

**1. Write your flows** as async scenarios in your own module (`flows.py`):

```python
from ParallelPlaywright import scenario

@scenario("search_product")
async def search_product(ctx):
    term = ctx.data.get("term", "dress")
    await ctx.page.goto(f"{ctx.base_url}/products", timeout=ctx.timeout_ms)
    await ctx.page.locator("#search_product").fill(term)
    await ctx.page.locator("#submit_search").click()
    await ctx.page.locator("text=SEARCHED PRODUCTS").wait_for(timeout=ctx.timeout_ms)
    return {"term": term}
```

Each scenario receives a [`ScenarioContext`](#scenariocontext) for one isolated
context/page ("one user").

**2. Use it from Robot:**

```robotframework
*** Settings ***
Library    ParallelPlaywright
...            base_url=https://www.automationexercise.com
...            scenario_modules=flows

*** Test Cases ***
Ten Users Search Concurrently In One Browser
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=search_product
    ...    repeat=10
    ...    max_active_contexts=6
    ...    block_heavy_resources=True
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[browser_processes]    1
```

Run it (ensure your `flows.py` is importable):

```bash
robot --pythonpath . your_suite.robot
```

## Keywords

| Keyword | Purpose |
|---------|---------|
| `Run Scenarios In Parallel` | Fan out scenarios across isolated contexts in one shared browser; returns a summary dict. |
| `Parallel Run Should Have Passed` | Fail the Robot test if any scenario run failed. |
| `Import Scenarios From` | Import scenario module(s) at runtime so their `@scenario` flows register. |
| `List Available Scenarios` | List currently registered scenario names. |

### `Run Scenarios In Parallel` arguments

| Argument | Default | Meaning |
|----------|---------|---------|
| `scenarios` | — | Comma-separated names (or a Robot list) of registered scenarios. |
| `repeat` | `1` | Multiply the whole set — `repeat=10` with one name = 10 concurrent users. |
| `browser_name` | `chromium` | `chromium`, `firefox`, or `webkit`. |
| `headless` | `True` | Headless browser. |
| `base_url` | library default | Base URL passed to each scenario. |
| `timeout_ms` | `30000` | Default per-page timeout. |
| `max_active_contexts` | `0` (unlimited) | Semaphore cap on simultaneously-active scenarios (RAM/CPU control). |
| `block_heavy_resources` | `True` | Abort image/media/font requests. |
| `isolation` | `context` | `context` = one isolated context per run; `page` = share one context (lightest). |
| `viewport_width` / `viewport_height` | `1280` / `720` | Viewport size. |
| `data` | `{}` | Dict made available to every scenario as `ctx.data`. |

The returned summary:

```python
{
  "total": 10, "passed": 10, "failed": 0,
  "elapsed_ms": 8421, "browser_processes": 1,
  "browser_name": "chromium", "isolation": "context",
  "max_active_contexts": 6,
  "results": [ {"run_id": 1, "scenario": "search_product",
                "status": "PASS", "elapsed_ms": 1903,
                "error": None, "data": {"term": "dress"}}, ... ],
}
```

## RAM & CPU tuning

- **`max_active_contexts`** — the main throttle. 50 scenarios with
  `max_active_contexts=8` opens contexts in a controlled wave instead of all at once.
- **`block_heavy_resources=True`** — drops images/media/fonts (the real memory cost).
  CSS is never blocked so layout/visibility checks stay reliable.
- **`isolation=page`** — when you don't need session isolation, share one context
  across runs for the lowest footprint.
- Low-memory Chromium flags (`--disable-dev-shm-usage`, `--disable-extensions`,
  `--disable-background-networking`, …) are applied automatically.

## ScenarioContext

| Field | Description |
|-------|-------------|
| `page` | Playwright async `Page` for this run. |
| `context` | The owning `BrowserContext`. |
| `base_url` | Base URL for the run. |
| `run_id` | 1-based index of this run. |
| `scenario_name` | Registered name. |
| `timeout_ms` | Default timeout. |
| `data` | Per-run parameters dict. |

## When to still use Pabot

This library parallelizes *work inside a browser*. If you need OS-level process
isolation (e.g. separate Python interpreters per suite) or you're parallelizing
non-browser tests, Pabot is still the right tool. The two compose fine.

## License

MIT — see [LICENSE](LICENSE).
