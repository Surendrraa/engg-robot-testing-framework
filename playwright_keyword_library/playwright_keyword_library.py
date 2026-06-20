from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Any, List

from robot.api.deco import keyword


class ElementHandle:
    def __init__(self, locator: Any) -> None:
        self.locator = locator


class PlaywrightKeywordLibrary:
    """Small Playwright-backed keyword library for this Robot suite.

    The existing tests were written with Selenium-style keyword names. This
    library keeps those Robot files readable while moving browser execution to
    Playwright.
    """

    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_VERSION = "1.0.0"

    def __init__(self, timeout: int = 10) -> None:
        self.timeout = float(timeout)
        self.screenshot_dir = Path("reports/screenshots")
        self._playwright = None
        self._browser = None
        self._context = None
        self._page = None
        self._last_dialog_message = None

    @keyword("Open Browser")
    def open_browser(self, url: str, browser: str = "chromium", headless: bool | str = True) -> None:
        from playwright.sync_api import sync_playwright

        self.close_browser()
        self._playwright = sync_playwright().start()
        browser_name = self._normalize_browser_name(browser)
        browser_type = getattr(self._playwright, browser_name)
        launch_options: dict[str, Any] = {"headless": self._to_bool(headless)}
        if browser_name == "chromium":
            launch_options["args"] = [
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--ozone-platform=wayland",
            ]
        self._browser = browser_type.launch(**launch_options)
        self._context = self._browser.new_context(viewport={"width": 1920, "height": 1080})
        self._page = self._context.new_page()
        self._page.on("dialog", self._accept_dialog)
        self._page.set_default_timeout(self._timeout_ms(self.timeout))
        self.go_to(url)

    @keyword("Close Browser")
    def close_browser(self) -> None:
        for item in (self._context, self._browser):
            if item is not None:
                try:
                    item.close()
                except Exception:
                    pass
        if self._playwright is not None:
            try:
                self._playwright.stop()
            except Exception:
                pass
        self._page = None
        self._context = None
        self._browser = None
        self._playwright = None

    @keyword("Go To")
    def go_to(self, url: str) -> None:
        self._active_page().goto(url, wait_until="domcontentloaded")

    @keyword("Title Should Be")
    def title_should_be(self, expected: str) -> None:
        actual = self._active_page().title()
        if actual != expected:
            raise AssertionError(f"Expected title '{expected}', got '{actual}'")

    @keyword("Handle Alert")
    def handle_alert(self, action: str = "ACCEPT") -> str:
        return self._last_dialog_message or ""

    @keyword("Set Browser Timeout")
    def set_browser_timeout(self, timeout: str | int | float) -> None:
        self.timeout = self._seconds(timeout)
        if self._page is not None:
            self._page.set_default_timeout(self._timeout_ms(self.timeout))

    @keyword("Set Screenshot Directory")
    def set_screenshot_directory(self, path: str) -> None:
        self.screenshot_dir = Path(path)
        self.screenshot_dir.mkdir(parents=True, exist_ok=True)

    @keyword("Capture Page Screenshot")
    def capture_page_screenshot(self, filename: str | None = None) -> str:
        self.screenshot_dir.mkdir(parents=True, exist_ok=True)
        safe_name = filename or f"screenshot-{int(time.time() * 1000)}.png"
        output = self.screenshot_dir / safe_name
        self._active_page().screenshot(path=str(output), full_page=True)
        return str(output)

    @keyword("Register Keyword To Run On Failure")
    def register_keyword_to_run_on_failure(self, _keyword_name: str) -> None:
        return None

    @keyword("Set Selenium Implicit Wait")
    def set_selenium_implicit_wait(self, _timeout: str | int | float) -> None:
        return None

    @keyword("Click Element")
    def click_element(self, locator: str | ElementHandle) -> None:
        target = self._locator(locator)
        try:
            target.scroll_into_view_if_needed(timeout=2000)
            target.click()
        except Exception:
            target.click(force=True)

    @keyword("Click Button")
    def click_button(self, locator: str | ElementHandle) -> None:
        self.click_element(locator)

    @keyword("Input Text")
    def input_text(self, locator: str | ElementHandle, text: str) -> None:
        target = self._locator(locator)
        target.fill(str(text))

    @keyword("Clear Element Text")
    def clear_element_text(self, locator: str | ElementHandle) -> None:
        self._locator(locator).fill("")

    @keyword("Select Checkbox")
    def select_checkbox(self, locator: str | ElementHandle) -> None:
        target = self._locator(locator)
        if not target.is_checked():
            target.check()

    @keyword("Select From List By Value")
    def select_from_list_by_value(self, locator: str | ElementHandle, value: str) -> None:
        self._locator(locator).select_option(value=str(value))

    @keyword("Select From List By Label")
    def select_from_list_by_label(self, locator: str | ElementHandle, label: str) -> None:
        self._locator(locator).select_option(label=str(label))

    @keyword("Get Text")
    def get_text(self, locator: str | ElementHandle) -> str:
        return self._locator(locator).inner_text().strip()

    @keyword("Get Element Count")
    def get_element_count(self, locator: str) -> int:
        return self._active_page().locator(self._selector(locator)).count()

    @keyword("Get WebElement")
    def get_webelement(self, locator: str) -> ElementHandle:
        target = self._locator(locator)
        target.wait_for(state="attached")
        return ElementHandle(target)

    @keyword("Get WebElements")
    def get_webelements(self, locator: str) -> List[ElementHandle]:
        items = self._active_page().locator(self._selector(locator)).all()
        return [ElementHandle(item) for item in items]

    @keyword("Execute JavaScript")
    @keyword("Execute Javascript")
    def execute_javascript(self, script: str, *args: Any) -> Any:
        page = self._active_page()
        filtered_args = [arg for arg in args if str(arg).upper() != "ARGUMENTS"]
        if filtered_args:
            prepared = [arg.locator.element_handle() if isinstance(arg, ElementHandle) else arg for arg in filtered_args]
            if script.strip() == "arguments[0].click()" and prepared:
                prepared[0].click()
                return None
            return page.evaluate("(payload) => Function('args', payload.script)(payload.args)", {"script": script, "args": prepared})
        return page.evaluate(script)

    @keyword("Scroll Element Into View")
    def scroll_element_into_view(self, locator: str | ElementHandle) -> None:
        self._locator(locator).scroll_into_view_if_needed()

    @keyword("Wait Until Page Contains Element")
    def wait_until_page_contains_element(self, locator: str, timeout: str | int | float | None = None) -> None:
        self._active_page().locator(self._selector(locator)).first.wait_for(
            state="attached",
            timeout=self._timeout_ms(timeout or self.timeout),
        )

    @keyword("Wait Until Element Is Visible")
    def wait_until_element_is_visible(self, locator: str, timeout: str | int | float | None = None) -> None:
        self._active_page().locator(self._selector(locator)).first.wait_for(
            state="visible",
            timeout=self._timeout_ms(timeout or self.timeout),
        )

    @keyword("Wait Until Page Contains")
    def wait_until_page_contains(self, text: str, timeout: str | int | float | None = None) -> None:
        deadline = time.monotonic() + self._seconds(timeout or self.timeout)
        last_text = ""
        while time.monotonic() < deadline:
            last_text = self._active_page().locator("body").inner_text(timeout=1000)
            if str(text) in last_text:
                return
            time.sleep(0.2)
        raise AssertionError(f"Page did not contain text '{text}'. Last body text: {last_text[:500]}")

    @keyword("Page Should Contain Element")
    def page_should_contain_element(self, locator: str) -> None:
        if self._active_page().locator(self._selector(locator)).count() < 1:
            raise AssertionError(f"Page does not contain element: {locator}")

    @keyword("Page Should Contain")
    def page_should_contain(self, text: str) -> None:
        body = self._active_page().locator("body").inner_text()
        if str(text) not in body:
            raise AssertionError(f"Page does not contain text: {text}")

    @keyword("Element Should Contain")
    def element_should_contain(self, locator: str | ElementHandle, expected: str) -> None:
        actual = self.get_text(locator)
        if str(expected) not in actual:
            raise AssertionError(f"Element text did not contain '{expected}'. Actual: '{actual}'")

    @keyword("Element Text Should Be")
    def element_text_should_be(self, locator: str | ElementHandle, expected: str) -> None:
        actual = self.get_text(locator)
        if actual != str(expected):
            raise AssertionError(f"Expected element text '{expected}', got '{actual}'")

    @keyword("Element Should Be Visible")
    def element_should_be_visible(self, locator: str | ElementHandle) -> None:
        if not self._locator(locator).is_visible():
            raise AssertionError(f"Element is not visible: {locator}")

    def _active_page(self) -> Any:
        if self._page is None:
            raise AssertionError("No active Playwright page. Call `Open Browser To Home Page` first.")
        return self._page

    def _accept_dialog(self, dialog: Any) -> None:
        self._last_dialog_message = dialog.message
        dialog.accept()

    def _locator(self, locator: str | ElementHandle) -> Any:
        if isinstance(locator, ElementHandle):
            return locator.locator
        return self._active_page().locator(self._selector(locator)).first

    def _selector(self, locator: str) -> str:
        value = str(locator)
        if value.startswith("css="):
            return value[4:]
        if value.startswith("xpath="):
            return "xpath=" + value[6:]
        if value.startswith("id="):
            return f"#{value[3:]}"
        if value.startswith("name="):
            return f"[name='{value[5:]}']"
        if value.startswith("link="):
            return f"a:has-text('{value[5:]}')"
        if value.startswith("//") or value.startswith("(//"):
            return "xpath=" + value
        return value

    def _normalize_browser_name(self, browser: str) -> str:
        name = str(browser).lower()
        if name in {"chrome", "chromium"}:
            return "chromium"
        if name in {"firefox", "webkit"}:
            return name
        raise AssertionError("Browser must be one of: chromium, chrome, firefox, webkit")

    def _to_bool(self, value: bool | str) -> bool:
        if isinstance(value, bool):
            return value
        return str(value).strip().lower() in {"true", "1", "yes", "on"}

    def _seconds(self, value: str | int | float) -> float:
        if isinstance(value, (int, float)):
            return float(value)
        match = re.match(r"^\s*(\d+(?:\.\d+)?)(ms|s)?\s*$", str(value))
        if not match:
            raise AssertionError(f"Invalid timeout value: {value}")
        amount = float(match.group(1))
        return amount / 1000 if match.group(2) == "ms" else amount

    def _timeout_ms(self, value: str | int | float) -> int:
        return int(self._seconds(value) * 1000)
