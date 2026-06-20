from __future__ import annotations

import asyncio
import time
from typing import Any, Dict, List
from urllib.parse import quote

from robot.api.deco import keyword


class AsyncPlaywrightLibrary:
    """Robot Framework custom library for async Playwright context workflows."""

    ROBOT_LIBRARY_SCOPE = "SUITE"
    ROBOT_LIBRARY_VERSION = "1.0.0"

    def __init__(self, default_timeout_ms: int = 30000) -> None:
        self.default_timeout_ms = int(default_timeout_ms)

    @keyword("Run Async Playwright Context Matrix")
    def run_async_playwright_context_matrix(
        self,
        url: str | None = None,
        browsers: int = 1,
        contexts_per_browser: int = 2,
        browser_name: str = "chromium",
        headless: bool | str = True,
        viewport_width: int = 1280,
        viewport_height: int = 720,
        timeout_ms: int | None = 60000,
        max_active_contexts: int = 0,
        block_heavy_resources: bool | str = False,
        hold_seconds: int = 0,
    ) -> Dict[str, Any]:
        """Launch browser processes and create isolated contexts concurrently.

        This is the Robot keyword to use when a plain Robot ``FOR`` loop is too
        sequential. It opens all requested contexts through ``asyncio.gather``
        and returns a summary dictionary Robot can assert on.
        """
        return self._run(
            self._run_context_matrix(
                url=url or self._default_data_url(),
                browsers=self._positive_int(browsers, "browsers"),
                contexts_per_browser=self._positive_int(contexts_per_browser, "contexts_per_browser"),
                browser_name=str(browser_name).lower(),
                headless=self._to_bool(headless),
                viewport_width=self._positive_int(viewport_width, "viewport_width"),
                viewport_height=self._positive_int(viewport_height, "viewport_height"),
                timeout_ms=int(timeout_ms or self.default_timeout_ms),
                max_active_contexts=max(0, int(max_active_contexts)),
                block_heavy_resources=self._to_bool(block_heavy_resources),
                hold_seconds=max(0, int(hold_seconds)),
            )
        )

    @keyword("Verify Playwright Context Storage Is Isolated")
    def verify_playwright_context_storage_is_isolated(
        self,
        contexts: int = 3,
        browser_name: str = "chromium",
        headless: bool | str = True,
        timeout_ms: int | None = None,
    ) -> Dict[str, Any]:
        """Create contexts in one browser and verify each has separate cookies."""
        return self._run(
            self._verify_context_storage_isolated(
                contexts=self._positive_int(contexts, "contexts"),
                browser_name=str(browser_name).lower(),
                headless=self._to_bool(headless),
                timeout_ms=int(timeout_ms or self.default_timeout_ms),
            )
        )

    async def _run_context_matrix(
        self,
        url: str,
        browsers: int,
        contexts_per_browser: int,
        browser_name: str,
        headless: bool,
        viewport_width: int,
        viewport_height: int,
        timeout_ms: int,
        max_active_contexts: int,
        block_heavy_resources: bool,
        hold_seconds: int,
    ) -> Dict[str, Any]:
        started_at = time.monotonic()
        async with self._playwright() as playwright:
            browser_type = self._browser_type(playwright, browser_name)
            launched_browsers = await asyncio.gather(
                *[
                    browser_type.launch(**self._launch_options(browser_name, headless))
                    for _ in range(browsers)
                ]
            )
            semaphore = asyncio.Semaphore(max_active_contexts) if max_active_contexts else None
            open_contexts = []

            async def open_context(browser: Any, browser_index: int, context_index: int) -> Dict[str, Any]:
                if semaphore is None:
                    return await self._open_context_page(
                        browser,
                        browser_index,
                        context_index,
                        url,
                        viewport_width,
                        viewport_height,
                        timeout_ms,
                        block_heavy_resources,
                        open_contexts,
                    )
                async with semaphore:
                    return await self._open_context_page(
                        browser,
                        browser_index,
                        context_index,
                        url,
                        viewport_width,
                        viewport_height,
                        timeout_ms,
                        block_heavy_resources,
                        open_contexts,
                    )

            try:
                pages = await asyncio.gather(
                    *[
                        open_context(browser, browser_index, context_index)
                        for browser_index, browser in enumerate(launched_browsers, start=1)
                        for context_index in range(1, contexts_per_browser + 1)
                    ]
                )
                if hold_seconds:
                    await asyncio.sleep(hold_seconds)
            finally:
                await asyncio.gather(*[context.close() for context in open_contexts], return_exceptions=True)
                await asyncio.gather(*[browser.close() for browser in launched_browsers], return_exceptions=True)

        elapsed_ms = int((time.monotonic() - started_at) * 1000)
        return {
            "browser_name": browser_name,
            "browsers": browsers,
            "contexts_per_browser": contexts_per_browser,
            "total_contexts": browsers * contexts_per_browser,
            "headless": headless,
            "elapsed_ms": elapsed_ms,
            "pages": pages,
        }

    async def _open_context_page(
        self,
        browser: Any,
        browser_index: int,
        context_index: int,
        url: str,
        viewport_width: int,
        viewport_height: int,
        timeout_ms: int,
        block_heavy_resources: bool,
        open_contexts: List[Any],
    ) -> Dict[str, Any]:
        context = await browser.new_context(viewport={"width": viewport_width, "height": viewport_height})
        open_contexts.append(context)
        page = await context.new_page()
        page.set_default_timeout(timeout_ms)
        if block_heavy_resources:
            async def block_or_continue(route: Any) -> None:
                if route.request.resource_type in {"image", "media", "font"}:
                    await route.abort()
                else:
                    await route.continue_()

            await context.route("**/*", block_or_continue)
        await page.goto(url, wait_until="domcontentloaded", timeout=timeout_ms)
        title = await page.title()
        page_url = page.url
        return {
            "browser": browser_index,
            "context": context_index,
            "title": title,
            "url": page_url,
        }

    async def _verify_context_storage_isolated(
        self,
        contexts: int,
        browser_name: str,
        headless: bool,
        timeout_ms: int,
    ) -> Dict[str, Any]:
        async with self._playwright() as playwright:
            browser_type = self._browser_type(playwright, browser_name)
            browser = await browser_type.launch(**self._launch_options(browser_name, headless))
            try:
                async def add_context_cookie(index: int) -> str:
                    context = await browser.new_context()
                    await context.add_cookies(
                        [
                            {
                                "name": "robot_context_id",
                                "value": f"context-{index}",
                                "url": "https://robot-framework.local/",
                            }
                        ]
                    )
                    cookies = await context.cookies("https://robot-framework.local/")
                    await context.close()
                    values = [cookie["value"] for cookie in cookies if cookie["name"] == "robot_context_id"]
                    if values != [f"context-{index}"]:
                        raise AssertionError(f"Context {index} cookie isolation failed: {values}")
                    return values[0]

                values = await asyncio.wait_for(
                    asyncio.gather(*[add_context_cookie(index) for index in range(1, contexts + 1)]),
                    timeout=timeout_ms / 1000,
                )
            finally:
                await browser.close()

        if len(set(values)) != contexts:
            raise AssertionError(f"Expected {contexts} isolated values, got {values}")
        return {"contexts": contexts, "isolated": True, "values": list(values)}

    def _run(self, coroutine: Any) -> Any:
        try:
            return asyncio.run(coroutine)
        except ModuleNotFoundError as error:
            if error.name == "playwright":
                raise AssertionError(
                    "Playwright Python package is not installed. Install optional dependencies with "
                    "`python3 -m pip install -r requirements-playwright.txt`."
                ) from error
            raise
        except Exception as error:
            message = str(error)
            if "Executable doesn't exist" in message:
                raise AssertionError(
                    "Playwright browser binaries are not installed. Run `python3 -m playwright install chromium` "
                    "or `rfbrowser init`, then re-run this Robot suite."
                ) from error
            if "Operation not permitted" in message or "sandbox_host_linux" in message:
                raise AssertionError(
                    "Playwright Chromium was blocked by the current execution sandbox. Run this Robot suite from a "
                    "normal terminal, or allow the command to run outside the managed sandbox."
                ) from error
            raise

    def _playwright(self) -> Any:
        from playwright.async_api import async_playwright

        return async_playwright()

    def _browser_type(self, playwright: Any, browser_name: str) -> Any:
        if browser_name not in {"chromium", "firefox", "webkit"}:
            raise AssertionError("browser_name must be one of: chromium, firefox, webkit")
        return getattr(playwright, browser_name)

    def _launch_options(self, browser_name: str, headless: bool) -> Dict[str, Any]:
        options: Dict[str, Any] = {"headless": headless}
        if browser_name == "chromium":
            options["args"] = [
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--ozone-platform=wayland",
            ]
        return options

    def _default_data_url(self) -> str:
        html = (
            "<!doctype html><html><head><title>Robot Custom Library</title></head>"
            "<body><h1>Async Playwright Custom Library</h1></body></html>"
        )
        return "data:text/html," + quote(html)

    def _positive_int(self, value: int | str, name: str) -> int:
        number = int(value)
        if number < 1:
            raise AssertionError(f"{name} must be greater than zero")
        return number

    def _to_bool(self, value: bool | str) -> bool:
        if isinstance(value, bool):
            return value
        return str(value).strip().lower() in {"true", "1", "yes", "on"}
