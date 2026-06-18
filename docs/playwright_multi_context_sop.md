# SOP: Playwright Multi-Browser and Multi-Context Flow

## Objective

This SOP explains how to use Robot Framework with Playwright/Browser Library to run multiple browser sessions and isolated contexts. It also explains when plain Robot keywords are enough and when a custom async Playwright helper is required.

## Target Scenario

The target flow is:

```text
Main Browser 1
  Context 1
  Context 2
  ...
  Context 10

Main Browser 2
  Context 1
  Context 2
  ...
  Context 10
```

Each context is isolated. Cookies, cache, local storage, and session data are not shared between contexts.

## Dependency Direction

For Playwright-based execution, use Robot Framework Browser Library:

```text
robotframework-browser==20.0.0
```

Selenium dependencies are not required for the Playwright flow:

```text
robotframework-seleniumlibrary
selenium
webdriver-manager
```

## Browser Library Initialization

After installing Browser Library, initialize Playwright browser assets:

```bash
rfbrowser init
```

In this environment, Playwright may reject the detected OS platform. If the host is detected as `ubuntu26.04-x64`, use:

```bash
PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 rfbrowser init
```

Use the same environment variable when running Robot tests:

```bash
PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 python3 -m robot tests
```

## Plain Robot Browser Library Flow

Robot Framework Browser Library can open multiple browsers and contexts directly.

Example:

```robot
*** Settings ***
Library    Browser

*** Test Cases ***
Two Browsers With Ten Contexts Each
    ${browser1}=    New Browser    browser=chromium    headless=False    reuse_existing=False
    ${browser2}=    New Browser    browser=chromium    headless=False    reuse_existing=False

    Switch Browser    ${browser1}
    FOR    ${index}    IN RANGE    1    11
        New Context    viewport={'width': 1280, 'height': 720}
        New Page       https://www.automationexercise.com/products
    END

    Switch Browser    ${browser2}
    FOR    ${index}    IN RANGE    1    11
        New Context    viewport={'width': 1280, 'height': 720}
        New Page       https://www.automationexercise.com/products
    END

    Close All Browsers
```

Important: `reuse_existing=False` is needed when calling `New Browser` multiple times with the same launch options. Otherwise Browser Library may reuse the first browser process.

## Sequential Behavior In Robot

Robot `FOR` loops run sequentially.

That means this flow:

```robot
FOR    ${index}    IN RANGE    1    11
    New Context
    New Page    https://www.automationexercise.com/products
END
```

opens context 1 first, then context 2, then context 3, and so on.

This is correct Robot behavior, but it is not suitable when the requirement is to open many contexts at the same time.

## Concurrent Approach

For true concurrent creation, use Playwright's async Python API and expose it as a custom Robot keyword.

Core Python idea:

```python
await asyncio.gather(
    *[
        open_context(browser, index)
        for index in range(1, 11)
    ]
)
```

For two browsers:

```python
browsers = await asyncio.gather(
    playwright.chromium.launch(headless=False),
    playwright.chromium.launch(headless=False),
)

await asyncio.gather(
    open_ten_contexts(browsers[0]),
    open_ten_contexts(browsers[1]),
)
```

This creates:

- 2 headed browser processes concurrently
- 10 contexts inside browser 1 concurrently
- 10 contexts inside browser 2 concurrently

## Worker Group Approach For Controlled Load

For larger runs, use worker groups. Each worker owns one browser process and a fixed number of contexts.

Recommended model:

```text
Worker 1 -> Browser 1 -> 10 contexts
Worker 2 -> Browser 2 -> 10 contexts
Worker 3 -> Browser 3 -> 10 contexts
Worker 4 -> Browser 4 -> 10 contexts
```

Each worker runs independently with `asyncio`, but the full run is still controlled from one Robot keyword.

High-level Python structure:

```python
async def run_worker(worker_id, contexts_per_worker):
    browser = await playwright.chromium.launch(headless=True)
    try:
        pages = await asyncio.gather(
            *[
                open_context_and_page(browser, worker_id, context_id)
                for context_id in range(1, contexts_per_worker + 1)
            ]
        )
        await asyncio.gather(
            *[
                run_ecommerce_actions(page)
                for page in pages
            ]
        )
    finally:
        await browser.close()

await asyncio.gather(
    run_worker(1, 10),
    run_worker(2, 10),
    run_worker(3, 10),
    run_worker(4, 10),
)
```

This gives better isolation than putting all contexts in one browser process.

## CPU-Friendly Parallelism

More parallelism can increase CPU usage if every context is active at once. Use throttling when CPU must stay stable.

Recommended controls:

- Prefer `headless=True` for load-style runs.
- Use a semaphore to limit active work:

```python
semaphore = asyncio.Semaphore(10)

async def run_context_with_limit(page):
    async with semaphore:
        await run_ecommerce_actions(page)
```

- Open contexts in batches instead of all at once:

```text
Batch 1: 10 active contexts
Batch 2: next 10 active contexts
Batch 3: next 10 active contexts
```

- Block heavy resources such as images, videos, fonts, and ads:

```python
async def block_heavy_resources(route):
    if route.request.resource_type in ["image", "media", "font"]:
        await route.abort()
    else:
        await route.continue_()

await context.route("**/*", block_heavy_resources)
```

- Reuse browser processes and pages instead of repeatedly closing and reopening them.
- Add pacing between repeated actions:

```python
await page.wait_for_timeout(500)
```

Balanced design:

```text
4 workers
4 browser processes
10 contexts per browser
only 8-12 contexts active at one time
heavy resources blocked
actions paced with small waits
```

This improves parallelism while reducing CPU spikes.

## Ecommerce Action Flow

For each context:

1. Open ecommerce products page:

```text
https://www.automationexercise.com/products
```

2. Wait for search input:

```text
css=#search_product
```

3. Fill search text:

```text
dress
```

4. Click search button:

```text
css=#submit_search
```

5. Validate:

```text
SEARCHED PRODUCTS
```

## Recommended Decision

Use plain Robot Browser Library when:

- Sequential browser/context creation is acceptable.
- The test is functional and readability is more important than simultaneous startup.

Use async Playwright helper when:

- Contexts must open at the same time.
- Multiple headed browsers must run in parallel.
- The test simulates load or multiple users.

## Notes

- Browser contexts are isolated sessions, not separate browser processes.
- Multiple main browsers consume more memory than multiple contexts in one browser.
- Headed mode requires a working display.
- Real ecommerce sites can be slow or block heavy parallel automation; use robust waits and avoid unnecessary navigation waits.
