"""Example consumer scenarios for robotframework-parallel-playwright.

These flows target automationexercise.com and live OUTSIDE the published
package on purpose: they show how someone *using* the library writes their own
scenarios. Point the library at this module with::

    Library    ParallelPlaywright    scenario_modules=flows

(run Robot with ``--pythonpath examples/parallel_playwright`` so it imports).
"""

from __future__ import annotations

from typing import Any, Dict
from urllib.parse import quote

from ParallelPlaywright import ScenarioContext, scenario

# --- Deterministic, network-free scenarios -------------------------------------
# These prove the engine's behaviour (concurrency in one browser + per-context
# isolation) without depending on any external website, so they are reliable in
# CI. The automationexercise flows below are live demos and subject to that
# public site's availability.

_LOCAL_PAGE = "data:text/html," + quote(
    "<!doctype html><html><head><title>RFPP</title></head>"
    "<body><h1>parallel playwright</h1></body></html>"
)

# A self-contained interactive page (form + button + live result) so headed,
# slow_mo runs show real typing/clicking with no network dependency.
_LOCAL_FORM = "data:text/html," + quote(
    "<!doctype html><html><head><title>RFPP Form</title>"
    "<style>body{font-family:sans-serif;padding:40px;font-size:24px}"
    "input,button{font-size:24px;padding:8px;margin:8px}"
    "#out{margin-top:24px;color:#0a7;font-weight:bold}</style></head>"
    "<body><h1>Parallel Playwright demo</h1>"
    "<input id='name' placeholder='your name'>"
    "<button id='go' onclick=\"document.getElementById('out').textContent="
    "'Hello '+document.getElementById('name').value+'!'\">Greet</button>"
    "<div id='out'></div></body></html>"
)


@scenario("local_form_demo")
async def local_form_demo(ctx: ScenarioContext) -> Dict[str, Any]:
    """Type a name, click Greet, and verify the result. Visible & deterministic.

    Run headed with slow_mo_ms + hold_seconds to watch each window do this.
    """
    await ctx.page.goto(_LOCAL_FORM)
    name = f"user-{ctx.run_id}"
    await ctx.page.locator("#name").fill(name)
    # force=True skips the "stable" actionability wait, which this headless WSL
    # Chromium build can fail to satisfy even for a static button.
    await ctx.page.locator("#go").click(force=True)
    out = ctx.page.locator("#out")
    await out.wait_for(state="visible", timeout=ctx.timeout_ms)
    text = await out.inner_text()
    expected = f"Hello {name}!"
    if text != expected:
        raise AssertionError(f"Expected {expected!r}, got {text!r}")
    return {"name": name, "result": text}


@scenario("local_page_loads")
async def local_page_loads(ctx: ScenarioContext) -> Dict[str, Any]:
    """Load an in-memory page and confirm it rendered (no network)."""
    await ctx.page.goto(_LOCAL_PAGE)
    title = await ctx.page.title()
    if title != "RFPP":
        raise AssertionError(f"Unexpected title: {title!r}")
    return {"run_id": ctx.run_id, "title": title}


@scenario("local_isolated_session")
async def local_isolated_session(ctx: ScenarioContext) -> Dict[str, Any]:
    """Prove each run's context has its own cookie jar (isolation)."""
    await ctx.page.goto(_LOCAL_PAGE)
    marker = f"run-{ctx.run_id}"
    await ctx.context.add_cookies(
        [{"name": "rfpp", "value": marker, "url": "https://rfpp.local/"}]
    )
    cookies = await ctx.context.cookies("https://rfpp.local/")
    got = [c["value"] for c in cookies if c["name"] == "rfpp"]
    if got != [marker]:
        raise AssertionError(f"Context isolation broken: expected [{marker!r}], got {got}")
    return {"marker": marker}


# --- Live demo scenarios (automationexercise.com) ------------------------------


async def _goto(ctx: ScenarioContext, path: str = "") -> None:
    url = ctx.base_url.rstrip("/") + ("/" + path.lstrip("/") if path else "")
    await ctx.page.goto(url, wait_until="domcontentloaded", timeout=ctx.timeout_ms)


async def _robust_click(ctx: ScenarioContext, locator: Any) -> None:
    """Click through automationexercise's animated ads/overlays.

    Native click waits for the element to be visible, stable and unobstructed;
    on this site the ad banners animate continuously so the element never goes
    "stable" and the click times out. ``dispatch_event('click')`` fires the DOM
    event directly, bypassing those actionability checks.
    """
    await locator.wait_for(state="attached", timeout=ctx.timeout_ms)
    try:
        await locator.click(timeout=4000)
    except Exception:
        await locator.click(force=True)


@scenario("home_page_loads")
async def home_page_loads(ctx: ScenarioContext) -> Dict[str, Any]:
    """Open the home page and confirm the title rendered."""
    await _goto(ctx)
    title = await ctx.page.title()
    if "Automation" not in title:
        raise AssertionError(f"Unexpected home title: {title!r}")
    return {"title": title}


@scenario("search_product")
async def search_product(ctx: ScenarioContext) -> Dict[str, Any]:
    """Search the products page and assert the results section appears.

    Term comes from ``ctx.data['term']`` so the same scenario fans out across
    contexts with different inputs.
    """
    term = str(ctx.data.get("term", "dress"))
    await _goto(ctx, "products")
    search = ctx.page.locator("#search_product")
    await search.wait_for(state="visible", timeout=ctx.timeout_ms)
    await search.fill(term)
    await _robust_click(ctx, ctx.page.locator("#submit_search").first)
    await ctx.page.locator("text=SEARCHED PRODUCTS").wait_for(state="visible", timeout=ctx.timeout_ms)
    count = await ctx.page.locator(".features_items .product-image-wrapper").count()
    return {"term": term, "result_count": count}


@scenario("add_first_product_to_cart")
async def add_first_product_to_cart(ctx: ScenarioContext) -> Dict[str, Any]:
    """Add the first listed product to the cart and verify the modal."""
    await _goto(ctx, "products")
    first = ctx.page.locator(".features_items .product-image-wrapper").first
    await first.wait_for(state="attached", timeout=ctx.timeout_ms)
    # Use the always-present product-info add-to-cart link (not the hover-only
    # overlay one); force-click fires a real event past the ad-stability wait.
    await _robust_click(ctx, first.locator(".productinfo a.add-to-cart").first)
    modal = ctx.page.locator("#cartModal .modal-body")
    await modal.wait_for(state="visible", timeout=ctx.timeout_ms)
    text = await modal.inner_text()
    if "added to cart" not in text.lower():
        raise AssertionError(f"Add-to-cart modal text unexpected: {text!r}")
    return {"modal_text": text.strip()[:80]}
