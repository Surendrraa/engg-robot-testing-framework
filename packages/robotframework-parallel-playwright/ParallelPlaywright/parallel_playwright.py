"""Robot Framework library that runs scenarios concurrently in ONE browser.

Why this exists
---------------
Robot Framework's test scheduler is single-threaded and sequential; it cannot
run test cases in parallel from inside a library. Pabot achieves parallelism by
launching N ``robot`` subprocesses, but each subprocess starts its *own*
Playwright browser process -- which is the RAM problem this library avoids.

Instead, the test *work* is written as async scenario coroutines (see
:mod:`registry`) and run together with ``asyncio.gather`` over many isolated
``BrowserContext`` objects that share a SINGLE browser process. A context is an
isolated session (separate cookies/storage/cache) but costs only a few MB,
versus ~150-300 MB for a full browser process. So 10 parallel "users" cost one
browser process here vs. ten under Pabot.

This module is application-agnostic: it ships no website-specific flows.
Consumers register their own scenarios with the ``@scenario`` decorator and load
them via ``scenario_modules=`` (init) or the ``Import Scenarios From`` keyword.

RAM / CPU controls
------------------
- ``max_active_contexts``: semaphore capping how many scenarios run at once.
- ``block_heavy_resources``: aborts image/media/font requests.
- ``isolation=page``: share one context (lightest) instead of one per run.
- Low-memory Chromium launch flags applied automatically.
"""

from __future__ import annotations

import asyncio
import importlib
import time
from typing import Any, Dict, List

from robot.api import logger
from robot.api.deco import keyword

from .registry import ScenarioContext, get_scenario, registered_names

#: Heavy, layout-irrelevant resource types. Stylesheets are intentionally NOT
#: blocked: without CSS, elements have no layout and Playwright's
#: visibility/stability checks time out. CSS is small; images/media/fonts are
#: the real RAM cost.
_HEAVY_RESOURCES = {"image", "media", "font"}

__version__ = "0.1.0"


class ParallelPlaywright:
    """Run registered scenarios concurrently inside one shared browser."""

    ROBOT_LIBRARY_SCOPE = "SUITE"
    ROBOT_LIBRARY_VERSION = __version__

    def __init__(
        self,
        base_url: str = "",
        default_timeout_ms: int = 30000,
        scenario_modules: str | List[str] | None = None,
    ) -> None:
        self.base_url = base_url
        self.default_timeout_ms = int(default_timeout_ms)
        if scenario_modules:
            self.import_scenarios_from(scenario_modules)

    # --- scenario loading ----------------------------------------------------

    @keyword("Import Scenarios From")
    def import_scenarios_from(self, modules: str | List[str]) -> List[str]:
        """Import one or more Python modules so their ``@scenario`` flows register.

        ``modules`` is a comma-separated string or a Robot list of importable
        dotted module paths (e.g. ``mypackage.flows``). Returns the full list of
        registered scenario names after import.
        """
        names = modules.split(",") if isinstance(modules, str) else list(modules)
        for name in (n.strip() for n in names):
            if not name:
                continue
            try:
                importlib.import_module(name)
            except ImportError as error:
                raise AssertionError(
                    f"Could not import scenario module '{name}': {error}. "
                    "Ensure it is on PYTHONPATH (Robot --pythonpath)."
                ) from error
        return registered_names()

    @keyword("List Available Scenarios")
    def list_available_scenarios(self) -> List[str]:
        """Return the names of every currently registered scenario."""
        return registered_names()

    # --- parallel run --------------------------------------------------------

    @keyword("Run Scenarios In Parallel")
    def run_scenarios_in_parallel(
        self,
        scenarios: str | List[str],
        repeat: int = 1,
        browser_name: str = "chromium",
        headless: bool | str = True,
        base_url: str | None = None,
        timeout_ms: int | None = None,
        max_active_contexts: int = 0,
        block_heavy_resources: bool | str = True,
        isolation: str = "context",
        viewport_width: int = 1280,
        viewport_height: int = 720,
        data: Dict[str, Any] | None = None,
        slow_mo_ms: int = 0,
        hold_seconds: int = 0,
        extra_browser_args: str | List[str] | None = None,
    ) -> Dict[str, Any]:
        """Fan out scenarios across isolated contexts in one shared browser.

        ``scenarios`` is a comma-separated string or Robot list of registered
        scenario names. ``repeat`` multiplies the whole set (``repeat=10`` with
        one name simulates 10 concurrent users running that flow). Returns a
        summary dict; it does NOT fail the test on scenario errors so the summary
        stays inspectable -- assert with ``Parallel Run Should Have Passed``.

        For watching a headed run: ``slow_mo_ms`` slows every Playwright action
        by that many milliseconds, and ``hold_seconds`` keeps each window open
        that long after its scenario finishes.
        """
        names = self._parse_scenarios(scenarios)
        run_plan = [name for _ in range(self._positive_int(repeat, "repeat")) for name in names]
        return self._run(
            self._execute(
                run_plan=run_plan,
                browser_name=str(browser_name).lower(),
                headless=self._to_bool(headless),
                base_url=base_url if base_url is not None else self.base_url,
                timeout_ms=int(timeout_ms or self.default_timeout_ms),
                max_active_contexts=max(0, int(max_active_contexts)),
                block_heavy_resources=self._to_bool(block_heavy_resources),
                isolation=str(isolation).lower(),
                viewport_width=self._positive_int(viewport_width, "viewport_width"),
                viewport_height=self._positive_int(viewport_height, "viewport_height"),
                data=dict(data or {}),
                slow_mo_ms=max(0, int(slow_mo_ms)),
                hold_seconds=max(0, int(hold_seconds)),
                extra_browser_args=self._parse_args(extra_browser_args),
            )
        )

    @keyword("Parallel Run Should Have Passed")
    def parallel_run_should_have_passed(self, summary: Dict[str, Any]) -> None:
        """Fail the Robot test if any scenario run in ``summary`` failed."""
        failed = summary.get("failed", 0)
        if failed:
            errors = [
                f"  run #{r['run_id']} {r['scenario']}: {r['error']}"
                for r in summary.get("results", [])
                if r["status"] == "FAIL"
            ]
            raise AssertionError(
                f"{failed}/{summary.get('total', 0)} scenario run(s) failed:\n" + "\n".join(errors)
            )

    # --- async core ----------------------------------------------------------

    async def _execute(
        self,
        run_plan: List[str],
        browser_name: str,
        headless: bool,
        base_url: str,
        timeout_ms: int,
        max_active_contexts: int,
        block_heavy_resources: bool,
        isolation: str,
        viewport_width: int,
        viewport_height: int,
        data: Dict[str, Any],
        slow_mo_ms: int,
        hold_seconds: int,
        extra_browser_args: List[str],
    ) -> Dict[str, Any]:
        if isolation not in {"context", "page"}:
            raise AssertionError("isolation must be 'context' or 'page'")
        started_at = time.monotonic()
        viewport = {"width": viewport_width, "height": viewport_height}
        semaphore = asyncio.Semaphore(max_active_contexts) if max_active_contexts else None

        async with self._playwright() as playwright:
            browser_type = self._browser_type(playwright, browser_name)
            browser = await browser_type.launch(
                **self._launch_options(browser_name, headless, slow_mo_ms, extra_browser_args)
            )
            shared_context = (
                await browser.new_context(viewport=viewport) if isolation == "page" else None
            )
            try:
                results = await asyncio.gather(
                    *[
                        self._run_one(
                            browser=browser,
                            shared_context=shared_context,
                            run_id=run_id,
                            name=name,
                            base_url=base_url,
                            timeout_ms=timeout_ms,
                            block_heavy_resources=block_heavy_resources,
                            viewport=viewport,
                            semaphore=semaphore,
                            data=data,
                            hold_seconds=hold_seconds,
                        )
                        for run_id, name in enumerate(run_plan, start=1)
                    ]
                )
            finally:
                if shared_context is not None:
                    await shared_context.close()
                await browser.close()

        elapsed_ms = int((time.monotonic() - started_at) * 1000)
        passed = sum(1 for r in results if r["status"] == "PASS")
        summary = {
            "total": len(results),
            "passed": passed,
            "failed": len(results) - passed,
            "elapsed_ms": elapsed_ms,
            "browser_processes": 1,
            "browser_name": browser_name,
            "isolation": isolation,
            "max_active_contexts": max_active_contexts or len(results),
            "results": results,
        }
        self._log_summary(summary)
        return summary

    async def _run_one(
        self,
        browser: Any,
        shared_context: Any,
        run_id: int,
        name: str,
        base_url: str,
        timeout_ms: int,
        block_heavy_resources: bool,
        viewport: Dict[str, int],
        semaphore: Any,
        data: Dict[str, Any],
        hold_seconds: int,
    ) -> Dict[str, Any]:
        async def execute() -> Dict[str, Any]:
            fn = get_scenario(name)
            own_context = shared_context is None
            context = await browser.new_context(viewport=viewport) if own_context else shared_context
            page = await context.new_page()
            page.set_default_timeout(timeout_ms)
            if block_heavy_resources:
                await page.route("**/*", self._block_route)
            started = time.monotonic()
            try:
                extra = await fn(
                    ScenarioContext(
                        page=page,
                        context=context,
                        base_url=base_url,
                        run_id=run_id,
                        scenario_name=name,
                        timeout_ms=timeout_ms,
                        data=dict(data),
                    )
                )
                status, error = "PASS", None
            except Exception as exc:  # scenario failures are captured, not raised
                status, error, extra = "FAIL", f"{type(exc).__name__}: {exc}", None
            finally:
                elapsed = int((time.monotonic() - started) * 1000)
                if hold_seconds:  # keep the window observable in headed runs
                    await asyncio.sleep(hold_seconds)
                await page.close()
                if own_context:
                    await context.close()
            return {
                "run_id": run_id,
                "scenario": name,
                "status": status,
                "elapsed_ms": elapsed,
                "error": error,
                "data": extra or {},
            }

        if semaphore is None:
            return await execute()
        async with semaphore:
            return await execute()

    async def _block_route(self, route: Any) -> None:
        if route.request.resource_type in _HEAVY_RESOURCES:
            await route.abort()
        else:
            await route.continue_()

    # --- helpers -------------------------------------------------------------

    def _run(self, coroutine: Any) -> Any:
        try:
            return asyncio.run(coroutine)
        except ModuleNotFoundError as error:
            if error.name == "playwright":
                raise AssertionError(
                    "Playwright Python package is not installed. Run "
                    "`pip install robotframework-parallel-playwright` and "
                    "`python -m playwright install chromium`."
                ) from error
            raise
        except Exception as error:
            message = str(error)
            if "Executable doesn't exist" in message:
                raise AssertionError(
                    "Playwright browser binaries are not installed. Run "
                    "`python -m playwright install chromium`, then re-run."
                ) from error
            if "Operation not permitted" in message or "sandbox_host_linux" in message:
                raise AssertionError(
                    "Playwright Chromium was blocked by the execution sandbox. Run this suite "
                    "from a normal terminal or outside the managed sandbox."
                ) from error
            raise

    def _playwright(self) -> Any:
        from playwright.async_api import async_playwright

        return async_playwright()

    def _browser_type(self, playwright: Any, browser_name: str) -> Any:
        if browser_name not in {"chromium", "firefox", "webkit"}:
            raise AssertionError("browser_name must be one of: chromium, firefox, webkit")
        return getattr(playwright, browser_name)

    def _launch_options(
        self,
        browser_name: str,
        headless: bool,
        slow_mo_ms: int = 0,
        extra_browser_args: List[str] | None = None,
    ) -> Dict[str, Any]:
        options: Dict[str, Any] = {"headless": headless}
        if slow_mo_ms:
            options["slow_mo"] = slow_mo_ms
        args: List[str] = []
        if browser_name == "chromium":
            args = [
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--disable-extensions",
                "--disable-background-networking",
                "--disable-renderer-backgrounding",
                "--mute-audio",
            ]
        args.extend(extra_browser_args or [])  # e.g. --ozone-platform=wayland on WSLg
        if args:
            options["args"] = args
        return options

    def _parse_args(self, value: str | List[str] | None) -> List[str]:
        if not value:
            return []
        parts = value.split(",") if isinstance(value, str) else list(value)
        return [str(part).strip() for part in parts if str(part).strip()]

    def _log_summary(self, summary: Dict[str, Any]) -> None:
        logger.info(
            f"Parallel run: {summary['passed']}/{summary['total']} passed in "
            f"{summary['elapsed_ms']} ms, 1 browser process, isolation={summary['isolation']}",
            also_console=True,
        )

    def _parse_scenarios(self, scenarios: str | List[str]) -> List[str]:
        if isinstance(scenarios, str):
            names = [part.strip() for part in scenarios.split(",")]
        else:
            names = [str(part).strip() for part in scenarios]
        names = [name for name in names if name]
        if not names:
            raise AssertionError("No scenarios provided")
        for name in names:
            get_scenario(name)  # validate up front
        return names

    def _positive_int(self, value: int | str, name: str) -> int:
        number = int(value)
        if number < 1:
            raise AssertionError(f"{name} must be greater than zero")
        return number

    def _to_bool(self, value: bool | str) -> bool:
        if isinstance(value, bool):
            return value
        return str(value).strip().lower() in {"true", "1", "yes", "on"}
