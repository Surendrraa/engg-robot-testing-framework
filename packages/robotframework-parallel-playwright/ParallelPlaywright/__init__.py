"""robotframework-parallel-playwright.

Run Robot Framework test work in parallel inside a single shared Playwright
browser -- many isolated contexts instead of many browser processes -- without
Pabot and without the per-process RAM cost.

Public API:
    ParallelPlaywright   Robot Framework library (import with ``Library  ParallelPlaywright``)
    scenario             decorator to register an async flow by name
    register             programmatic scenario registration
    ScenarioContext      object passed to each scenario coroutine
"""

from .parallel_playwright import ParallelPlaywright, __version__
from .registry import ScenarioContext, register, registered_names, scenario

__all__ = [
    "ParallelPlaywright",
    "ScenarioContext",
    "scenario",
    "register",
    "registered_names",
    "__version__",
]
