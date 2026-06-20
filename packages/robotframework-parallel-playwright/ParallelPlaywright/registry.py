"""Scenario registry for the parallel Playwright runner.

A *scenario* is an async Python coroutine that drives one isolated browser
context (one simulated user). Scenarios are registered by name and executed
concurrently by :class:`ParallelPlaywright`. This is the unit of parallelism:
Robot Framework's own scheduler is sequential, so the test *work* is moved into
these coroutines and run together under a single shared browser process.

This module is intentionally application-agnostic. Consumers register their own
flows from their own packages -- nothing about any particular website lives here.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Awaitable, Callable, Dict


@dataclass
class ScenarioContext:
    """Everything a scenario coroutine needs for one concurrent run.

    One ``ScenarioContext`` maps to one isolated Playwright context+page, i.e.
    one simulated user. ``data`` carries per-run parameters (search term, creds,
    a row from a data table) so the same scenario can be fanned out with
    variation.
    """

    page: Any
    context: Any
    base_url: str
    run_id: int
    scenario_name: str
    timeout_ms: int
    data: Dict[str, Any] = field(default_factory=dict)


#: Signature every scenario must follow. It may return a dict of extra data to
#: surface in the run summary; raising is treated as a failed run.
ScenarioFn = Callable[[ScenarioContext], Awaitable[Dict[str, Any] | None]]

_REGISTRY: Dict[str, ScenarioFn] = {}


def scenario(name: str) -> Callable[[ScenarioFn], ScenarioFn]:
    """Decorator registering an async scenario coroutine under ``name``."""

    def decorator(fn: ScenarioFn) -> ScenarioFn:
        register(name, fn)
        return fn

    return decorator


def register(name: str, fn: ScenarioFn) -> None:
    """Register ``fn`` under ``name`` (programmatic alternative to the decorator)."""
    key = str(name).strip()
    if not key:
        raise ValueError("Scenario name must be a non-empty string")
    _REGISTRY[key] = fn


def get_scenario(name: str) -> ScenarioFn:
    key = str(name).strip()
    if key not in _REGISTRY:
        raise AssertionError(
            f"Unknown scenario '{key}'. Registered scenarios: "
            f"{', '.join(registered_names()) or '(none)'}. "
            "Did you load your scenario module via scenario_modules= or 'Import Scenarios From'?"
        )
    return _REGISTRY[key]


def registered_names() -> list[str]:
    return sorted(_REGISTRY)


def clear() -> None:
    """Remove all registered scenarios (primarily for tests)."""
    _REGISTRY.clear()
