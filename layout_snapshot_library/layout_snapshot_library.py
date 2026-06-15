from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Any, Dict, Optional


class LayoutSnapshotLibrary:
    def __init__(
        self,
        driver: Any = None,
        settle_interval: float = 0.3,
        settle_timeout: float = 10.0,
        settle_required_matches: int = 2,
    ) -> None:
        self.driver = driver
        self.settle_interval = float(settle_interval)
        self.settle_timeout = float(settle_timeout)
        self.settle_required_matches = max(2, int(settle_required_matches))

    def capture_stable_layout_snapshot(self, output_file_path: str) -> None:
        snapshot = self._wait_until_stable()
        output_path = Path(output_file_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(snapshot, encoding="utf-8")

    def verify_ui_layout_against_baseline(self, baseline_file_path: str, pixel_tolerance: int = 2) -> None:
        baseline_path = Path(baseline_file_path)
        expected_lines = baseline_path.read_text(encoding="utf-8").splitlines()
        actual_lines = self._wait_until_stable().splitlines()
        geom_re = re.compile(
            r"^POS:\[T:(?P<top>-?\d+),L:(?P<left>-?\d+)\] "
            r"TAG:\[(?P<tag>[^\]]*)\] "
            r"CLS:\[(?P<classes>[^\]]*)\] "
            r"BOX:\[W:(?P<width>-?\d+),H:(?P<height>-?\d+)\] "
            r"TEXT:\[(?P<text>.*)\]$"
        )

        def parsed(line: str) -> Optional[Dict[str, Any]]:
            match = geom_re.match(line)
            if not match:
                return None
            data = match.groupdict()
            return {
                "top": int(data["top"]),
                "left": int(data["left"]),
                "width": int(data["width"]),
                "height": int(data["height"]),
                "stable": (data["tag"], data["classes"], data["text"]),
            }

        tolerance = max(0, int(pixel_tolerance))
        max_lines = max(len(expected_lines), len(actual_lines))
        infractions = []

        for index in range(max_lines):
            expected = expected_lines[index] if index < len(expected_lines) else None
            actual = actual_lines[index] if index < len(actual_lines) else None

            if expected == actual:
                continue
            if expected is None:
                infractions.append(
                    f"Line {index + 1}: NEW ELEMENT\n"
                    f"  Expected: <missing>\n"
                    f"  Actual:   {actual}"
                )
                continue
            if actual is None:
                infractions.append(
                    f"Line {index + 1}: MISSING ELEMENT\n"
                    f"  Expected: {expected}\n"
                    f"  Actual:   <missing>"
                )
                continue

            expected_parts = parsed(expected)
            actual_parts = parsed(actual)
            if expected_parts and actual_parts and expected_parts["stable"] == actual_parts["stable"]:
                if (
                    abs(expected_parts["top"] - actual_parts["top"]) <= tolerance
                    and abs(expected_parts["left"] - actual_parts["left"]) <= tolerance
                    and abs(expected_parts["width"] - actual_parts["width"]) <= tolerance
                    and abs(expected_parts["height"] - actual_parts["height"]) <= tolerance
                ):
                    continue

            infractions.append(
                f"Line {index + 1}: LAYOUT BREACH\n"
                f"  Expected: {expected}\n"
                f"  Actual:   {actual}"
            )

        if infractions:
            raise AssertionError(
                "UI layout snapshot mismatch detected.\n"
                f"Baseline: {baseline_path}\n"
                f"Pixel tolerance: {tolerance}\n"
                f"Infractions: {len(infractions)}\n\n"
                + "\n\n".join(infractions)
            )

    def _prepare_capture(self) -> None:
        """Force the page into a deterministic state before reading geometry.

        Removes the known sources of run-to-run noise: scroll offset (rect is
        viewport-relative), in-flight CSS animations/transitions, focus/caret
        rendering, and unsettled web fonts. Applied identically on baseline
        capture and verification so both sides are measured under the same
        conditions.
        """
        driver = self._active_driver()
        if driver is None:
            raise AssertionError("No active Selenium WebDriver session found")

        driver.execute_script(
            r"""
window.scrollTo(0, 0);
if (document.activeElement && document.activeElement.blur) {
  document.activeElement.blur();
}
var existing = document.getElementById('__layout_snapshot_freeze__');
if (!existing) {
  var style = document.createElement('style');
  style.id = '__layout_snapshot_freeze__';
  style.innerHTML = '*,*::before,*::after{' +
    'animation:none!important;' +
    'transition:none!important;' +
    'caret-color:transparent!important;}';
  document.head.appendChild(style);
}
"""
        )
        try:
            driver.execute_async_script(
                "var done = arguments[0];"
                "if (document.fonts && document.fonts.ready) {"
                "  document.fonts.ready.then(function(){"
                "    requestAnimationFrame(function(){requestAnimationFrame(done);});"
                "  });"
                "} else {"
                "  requestAnimationFrame(function(){requestAnimationFrame(done);});"
                "}"
            )
        except Exception:
            pass

    def _wait_until_stable(self) -> str:
        """Capture repeatedly until the snapshot stops changing.

        The page is proven quiescent only when consecutive captures are
        byte-identical ``settle_required_matches`` times in a row. Anything
        still loading, animating, or reflowing keeps producing a different
        snapshot, which resets the streak. This is how we guarantee an
        unchanged page never reports a diff across repeated runs: same settled
        state in, same bytes out.
        """
        self._prepare_capture()
        deadline = time.monotonic() + self.settle_timeout
        previous: Optional[str] = None
        stable_count = 1
        current = self._capture_stable_layout_snapshot_text()

        while time.monotonic() < deadline:
            previous = current
            time.sleep(self.settle_interval)
            current = self._capture_stable_layout_snapshot_text()
            if current == previous:
                stable_count += 1
                if stable_count >= self.settle_required_matches:
                    return current
            else:
                stable_count = 1

        raise AssertionError(
            "Page never reached a stable layout within "
            f"{self.settle_timeout:g}s (consecutive identical captures required: "
            f"{self.settle_required_matches}). The last two captures still differed, "
            "meaning the page is still animating, loading, or reflowing."
        )

    def _capture_stable_layout_snapshot_text(self) -> str:
        driver = self._active_driver()
        if driver is None:
            raise AssertionError("No active Selenium WebDriver session found")

        script = r"""
const dynamicClassRe = /(^|[-_])(?:[a-f0-9]{8,}|[a-z0-9]*\d{4,}[a-z0-9]*|css-[a-z0-9]{5,}|sc-[a-z0-9]{5,})(?=$|[-_])/i;
const dateRe = /\b(?:\d{1,4}[\/.-]\d{1,2}[\/.-]\d{1,4}|\d{1,2}:\d{2}(?::\d{2})?(?:\s?[AP]M)?|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4})\b/gi;
const uuidRe = /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/gi;
const hashRe = /\b[a-f0-9]{10,}\b/gi;
const tokenRe = /\b(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{4,}\b/g;
const numberRe = /\b\d+(?:\.\d+)?\b/g;
const statusPrefixRe = /^\s*((?:Error|Success|Warning|Info|Alert|Failed|Passed|Loading|Ready):)\s*/i;

function clean(value) {
  return String(value || '').replace(/\s+/g, ' ').trim();
}
function maskText(value) {
  let text = clean(value);
  if (!text) return '';
  let prefix = '';
  const prefixMatch = text.match(statusPrefixRe);
  if (prefixMatch) {
    prefix = prefixMatch[1] + ' ';
    text = text.slice(prefixMatch[0].length);
  }
  text = text
    .replace(uuidRe, '[VAL]')
    .replace(dateRe, '[VAL]')
    .replace(hashRe, '[VAL]')
    .replace(tokenRe, '[VAL]')
    .replace(numberRe, '#');
  return clean(prefix + text);
}
function cleanClasses(value) {
  const raw = typeof value === 'string' ? value : '';
  const out = [];
  for (const cls of raw.split(/\s+/)) {
    if (!cls) continue;
    out.push(dynamicClassRe.test(cls) ? 'VAL' : cls.replace(hashRe, 'VAL').replace(tokenRe, 'VAL'));
  }
  return out.join(' ');
}
function isRendered(el) {
  const style = window.getComputedStyle(el);
  if (!style || style.display === 'none' || style.visibility === 'hidden') return false;
  const rect = el.getBoundingClientRect();
  return rect.width > 0 && rect.height > 0;
}
function escapeBoundedField(value) {
  return clean(value).replace(/[\[\]\r\n]+/g, ' ');
}
function escapeTextField(value) {
  return clean(value).replace(/[\r\n]+/g, ' ');
}

const rows = [];
const nodes = document.getElementsByTagName('*');
for (let i = 0; i < nodes.length; i++) {
  const el = nodes[i];
  if (!isRendered(el)) continue;
  const rect = el.getBoundingClientRect();
  rows.push({
    top: Math.round(rect.top),
    left: Math.round(rect.left),
    width: Math.round(rect.width),
    height: Math.round(rect.height),
    tag: el.tagName.toLowerCase(),
    classes: cleanClasses(el.className),
    text: maskText(el.innerText || el.textContent || '')
  });
}
rows.sort((a, b) => (a.top - b.top) || (a.left - b.left) || a.tag.localeCompare(b.tag));
return rows.map(row =>
  'POS:[T:' + row.top + ',L:' + row.left + '] ' +
  'TAG:[' + row.tag + '] ' +
  'CLS:[' + escapeBoundedField(row.classes) + '] ' +
  'BOX:[W:' + row.width + ',H:' + row.height + '] ' +
  'TEXT:[' + escapeTextField(row.text) + ']'
).join('\n');
"""
        value = driver.execute_script(script)
        return value if isinstance(value, str) else str(value or "")

    def _active_driver(self) -> Any:
        if self.driver is not None:
            return self.driver
        try:
            from robot.libraries.BuiltIn import BuiltIn

            return BuiltIn().get_library_instance("SeleniumLibrary").driver
        except Exception:
            return None
