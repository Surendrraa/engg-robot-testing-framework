# 🤖 Robot Framework Command Reference

This guide provides the most essential commands for running, debugging, and managing your Robot Framework automation project.

---

## 1. Basic Execution

| Command | Description |
|:---|:---|
| `robot tests/` | Run all tests in the `tests` directory |
| `robot tests/auth/` | Run all tests in a specific folder (Module) |
| `robot tests/auth/TC01_register_user.robot` | Run a single test file |
| `robot --test "TC01*" tests/` | Run tests by name pattern |

---

## 2. Managing Output & Reports

| Command | Description |
|:---|:---|
| `robot --outputdir reports tests/` | Save all reports (log, report, output) in the `reports/` folder |
| `robot --timestampoutputs tests/` | Add a timestamp to report files (prevents overwriting) |
| `robot --reporttitle "My Test Report" tests/` | Customize the title of the HTML report |

---

## 3. Dynamic Variables (Overriding Config)

You can override variables defined in `config/config.py` via the command line without changing the code.

| Command | Description |
|:---|:---|
| `robot --variable BROWSER:firefox tests/` | Run tests on Firefox instead of the default |
| `robot --variable HEADLESS:True tests/` | **Run in Headless Mode** (no UI) |
| `robot --variable HEADLESS:False tests/` | **Run in Head Mode** (UI visible) |
| `robot --variable BASE_URL:https://staging.com tests/` | Run against a staging environment |

---

## 4. Tagging & Filtering

Tags allow you to categorize tests (e.g., `smoke`, `regression`, `slow`).

| Command | Description |
|:---|:---|
| `robot --include smoke tests/` | Run only tests tagged with `smoke` |
| `robot --exclude slow tests/` | Run everything EXCEPT tests tagged with `slow` |
| `robot -i smoke -e slow tests/` | Run smoke tests but exclude slow ones |

---

## 5. Debugging & Logs

| Command | Description |
|:---|:---|
| `robot --loglevel DEBUG tests/` | Show more detailed logs (useful for troubleshooting) |
| `robot --dryrun tests/` | Check for syntax errors without actually running the tests |
| `robot --rerunfailed reports/output.xml tests/` | Re-run only the tests that failed in the previous run |

---

## 6. Parallel Execution (Multi-threading)

Using the `pabot` library (must be installed: `pip install robotframework-pabot`).

| Command | Description |
|:---|:---|
| `pabot --processes 4 --outputdir reports tests/` | Run tests across 4 parallel browser instances |
| `pabot --testlevelsplit tests/` | Split execution at the test case level (instead of suite level) |

---

## 7. Useful Tips
1. **Headless vs Head Mode**: Check `config/config.py` and set `HEADLESS = True` or `False`.
2. **Screenshots**: Robot Framework auto-captures a screenshot on failure and links it in `reports/log.html`.
3. **Log.html**: This is your best friend. It shows exactly which keyword failed and why.
