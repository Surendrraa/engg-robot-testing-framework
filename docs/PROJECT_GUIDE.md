# Robot Framework + Selenium - Complete Project Guide
## Project: AutomationExercise.com Test Automation
## URL: https://www.automationexercise.com

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Folder Structure Explained](#2-folder-structure-explained)
3. [File-by-File Breakdown](#3-file-by-file-breakdown)
4. [Locators Deep Dive](#4-locators-deep-dive)
5. [Robot Framework Syntax & Commands](#5-robot-framework-syntax--commands)
6. [Page Object Model (POM) Explained](#6-page-object-model-pom-explained)
7. [Keyword Layering Architecture](#7-keyword-layering-architecture)
8. [Test Data Strategy](#8-test-data-strategy)
9. [How to Run Tests](#9-how-to-run-tests)
10. [Common Robot Framework Commands Reference](#10-common-robot-framework-commands-reference)
11. [Interview Q&A — Framework & Architecture](#11-interview-qa--framework--architecture)
12. [Interview Q&A — Robot Framework Syntax](#12-interview-qa--robot-framework-syntax)
13. [Interview Q&A — Selenium & Locators](#13-interview-qa--selenium--locators)
14. [Interview Q&A — Page Object Model](#14-interview-qa--page-object-model)
15. [Interview Q&A — Test Design & Best Practices](#15-interview-qa--test-design--best-practices)
16. [Interview Q&A — Real Scenario Based](#16-interview-qa--real-scenario-based)
17. [Troubleshooting Guide](#17-troubleshooting-guide)
18. [Parallel Execution with Pabot](#18-parallel-execution-with-pabot)

---

## 1. PROJECT OVERVIEW

This is a **keyword-driven test automation framework** that uses:
- **Robot Framework** — keyword-driven test framework (`.robot` files)
- **Selenium WebDriver** — browser automation (via SeleniumLibrary)
- **Resource files** — reusable keywords, locators, and variables (`.resource` files)

### What it tests:
An e-commerce website (https://www.automationexercise.com) with **26 end-to-end test cases** covering:
- User registration, login, logout
- Product browsing, searching, categories, brands
- Shopping cart operations
- Full checkout and payment flow
- Contact form submission
- Subscription
- Page navigation and scrolling

### Why this combination?
| Layer | Technology | Purpose |
|-------|-----------|---------|
| Test Runner | Robot Framework | Human-readable test cases, reporting |
| Browser Control | Selenium WebDriver | Interact with web elements (via SeleniumLibrary) |
| Keywords | .resource files | Reusable actions per feature |
| Locators | .resource files | Element addresses separated by page |
| Variables | config/*.py files | Test data, URLs, credentials (Python-based) |

---

## 2. FOLDER STRUCTURE EXPLAINED

```
robost-framework/
|
|-- resources/                      # ROBOT FRAMEWORK RESOURCES
|   |-- common.resource             # Shared keywords (browser open/close, unique email)
|   |-- auth_keywords.resource      # Keywords for login, signup, registration
|   |-- product_keywords.resource   # Keywords for products, search, categories
|   |-- cart_keywords.resource      # Keywords for cart operations
|   |-- checkout_keywords.resource  # Keywords for checkout + payment
|   |-- subscription_keywords.resource  # Keywords for subscription
|   |
|   |-- locators/                   # ALL ELEMENT LOCATORS (separated by feature)
|       |-- auth_locators.resource
|       |-- products_locators.resource
|       |-- cart_locators.resource
|       |-- checkout_locators.resource
|       |-- payment_locators.resource
|       |-- contact_locators.resource
|       |-- navigation_locators.resource
|       |-- subscription_locators.resource
|
|-- tests/                          # ROBOT FRAMEWORK TEST SUITES
|   |-- auth/                       # TC01-TC05: Register, Login, Logout
|   |-- contact/                    # TC06: Contact Us Form
|   |-- navigation/                 # TC07, TC25, TC26: Page navigation, scrolling
|   |-- products/                   # TC08, TC09, TC18, TC19, TC21: Products
|   |-- subscription/               # TC10, TC11: Subscription
|   |-- cart/                       # TC12, TC13, TC17, TC20, TC22: Cart
|   |-- checkout/                   # TC14-TC16, TC23, TC24: Checkout + Payment
|
|-- config/                         # CONFIGURATION
|   |-- config.py                   # Base URL, browser, timeout settings
|   |-- test_data.py                # Python version of test data
|
|-- utils/                          # UTILITIES
|   |-- __init__.py
|   |-- logger.py                   # Logging helper
|
|-- reports/                        # AUTO-GENERATED after test run
|   |-- log.html                    # Detailed execution log
|   |-- report.html                 # Summary report
|   |-- output.xml                  # Raw XML output
|
|-- requirements.txt                # Python dependencies
|-- test-requirements.md            # Original test specification
|-- PROJECT_GUIDE.md                # THIS FILE
```

### WHY THIS STRUCTURE?

| Directory | Purpose | When to modify |
|-----------|---------|----------------|
| `resources/locators/` | Change when element selectors change | Element ID/class/attribute changed |
| `resources/*_keywords.resource` | Change when test workflow changes | New step added to a flow |
| `tests/` | Change when test case logic changes | New test case or scenario update |
| `config/` | Change when environment changes | Different URL, browser, timeout |

---

## 3. FILE-BY-FILE BREAKDOWN

### resources/locators/auth_locators.resource — Element Addresses
**What:** Stores all locators (element addresses) for auth pages.
**Why:** If a developer changes an element's ID or class, you update ONE file.

```robot
*** Variables ***
${LOGIN_EMAIL_INPUT}        css=input[data-qa='login-email']
${LOGIN_PASSWORD_INPUT}     css=input[data-qa='login-password']
${LOGIN_BUTTON}             css=button[data-qa='login-button']
${SIGNUP_NAME_INPUT}        css=input[data-qa='signup-name']
```

### resources/auth_keywords.resource — Auth Actions
**What:** Reusable keywords (actions) for login, signup, registration.
**Why:** Write login steps once, use in 10+ test files.

```robot
*** Keywords ***
Login With Credentials
    [Arguments]    ${email}    ${password}
    Input Text    ${LOGIN_EMAIL_INPUT}    ${email}
    Input Text    ${LOGIN_PASSWORD_INPUT}    ${password}
    Click Button    ${LOGIN_BUTTON}
```

### resources/common.resource — Shared Keywords
**What:** Browser setup, unique email generation, shared locators.

Key sections:
- `*** Settings ***` — Library imports
- `*** Variables ***` — Navbar locators, footer locators, modal locators
- `*** Keywords ***` — Open/Close browser, Generate Unique Email

```robot
*** Keywords ***
Open Browser To Home Page
    # Creates headless Chrome with options
    # Navigates to BASE_URL
    # Sets implicit wait

Generate Unique Email With Prefix
    # Uses timestamp to create unique email every run
    # e.g., tc01_register_1711456789@testmail.com
```

### config/test_data.py & config/config.py — Test Data
**What:** Central place for ALL test data values and environment settings.
**Why:** Maintains a single source of truth in Python, imported into Robot suites via `Variables` setting.

```python
# config/config.py
BASE_URL = "https://www.automationexercise.com"
BROWSER  = "chrome"

# config/test_data.py
VALID_EMAIL = "robottest_automation@testmail.com"
VALID_PASS  = "Test@12345"
FIRST_NAME  = "Robot"
```

### resources/locators/auth_locators.resource — Locator File Example
**What:** ONLY locator definitions — no keywords, no logic.

```robot
*** Variables ***
# Login Page
${LOGIN_EMAIL_INPUT}     css=input[data-qa='login-email']
${LOGIN_PASSWORD_INPUT}  css=input[data-qa='login-password']
${LOGIN_BUTTON}          css=button[data-qa='login-button']

# Registration Form
${REG_TITLE_MR_RADIO}    id=id_gender1
${REG_PASSWORD_INPUT}    css=input[data-qa='password']
${REG_DAYS_DROPDOWN}     id=days
# ... etc
```

### resources/auth_keywords.resource — Keyword File Example
**What:** Reusable keyword definitions that use locators.

```robot
*** Keywords ***
Login With Credentials
    [Arguments]    ${email}    ${password}
    Input Text    ${LOGIN_EMAIL_INPUT}    ${email}
    Input Text    ${LOGIN_PASSWORD_INPUT}    ${password}
    Click Button    ${LOGIN_BUTTON}
    Sleep    2s
```

### tests/auth/TC01_register_user.robot — Test File Example
**What:** The actual test case — reads like plain English.

```robot
*** Settings ***
Resource    ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource    ../../resources/common.resource
Test Setup       Open Browser To Home Page
Test Teardown    Close Test Browser

*** Test Cases ***
TC01 Register User
    Navigate To Login Page
    Verify New User Signup Visible
    ${unique_email}=    Generate Unique Email With Prefix    tc01_register
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ...
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    Verify Logged In As    ${SIGNUP_NAME}
    Delete Account
    Verify Account Deleted
```

---

## 4. LOCATORS DEEP DIVE

### What is a Locator?
A locator is an **address** to find an element on a web page. Like a GPS coordinate for a button, input field, or text.

### Locator Types Used in This Project

| Type | Syntax | When to Use | Example |
|------|--------|-------------|---------|
| **CSS Selector** | `css=...` | Most common, fast, readable | `css=input[data-qa='login-email']` |
| **ID** | `id=...` | When element has unique ID | `id=search_product` |
| **XPath** | `xpath=...` | Complex/dynamic elements | `xpath=//a[contains(text(),'Logout')]` |
| **data-qa attribute** | `css=[data-qa='...']` | Best practice — stable selectors | `css=button[data-qa='pay-button']` |

### Locator Strategy Priority (Best to Worst):
1. **data-qa / data-testid** — Added specifically for testing, never changes
2. **ID** — Usually unique, fast lookup
3. **CSS Selector** — Flexible, readable, fast
4. **XPath** — Most powerful, but slower and brittle

### Real Examples from This Project:

```robot
# GOOD: Uses data-qa attribute (stable, test-specific)
${LOGIN_EMAIL_INPUT}    css=input[data-qa='login-email']

# GOOD: Uses unique ID
${SEARCH_INPUT}    id=search_product

# GOOD: CSS with class combination
${CART_DELETE_BUTTON}    css=a.cart_quantity_delete

# OK: XPath for text-based matching (when no better option)
${NAV_LOGOUT_LINK}    xpath=//a[contains(text(),'Logout')]

# OK: XPath for parent-child relationship
${PRODUCT_AVAILABILITY}    xpath=//b[contains(text(),'Availability')]/parent::p
```

### How Locators Flow Through the Framework:

```
locators/auth_locators.resource     → Defines: ${LOGIN_EMAIL_INPUT}
        ↓
auth_keywords.resource              → Uses: Input Text ${LOGIN_EMAIL_INPUT} ${email}
        ↓
TC02_login_valid.robot              → Calls: Login With Credentials ${email} ${pass}
```

---

## 5. ROBOT FRAMEWORK SYNTAX & COMMANDS

### File Sections (every .robot/.resource file has these):

```robot
*** Settings ***       # Imports: Libraries, Resources, Setup/Teardown
*** Variables ***      # Constants: Locators, URLs, test data
*** Keywords ***       # Reusable steps (like functions)
*** Test Cases ***     # Actual test scenarios (only in .robot files)
```

### Settings Section — Common Patterns:

```robot
*** Settings ***
Library           SeleniumLibrary          # Import Selenium keywords
Library           String                   # String manipulation
Library           Collections              # List/Dict operations
Resource          ../../resources/common.resource    # Import shared keywords
Test Setup        Open Browser To Home Page          # Run before EACH test
Test Teardown     Close Test Browser                 # Run after EACH test
```

### Variables Section — Defining Variables:

```robot
*** Variables ***
${SCALAR_VAR}     single value              # Scalar (string)
${URL}            https://example.com       # Another scalar
@{LIST_VAR}       item1    item2    item3   # List variable
&{DICT_VAR}       key1=val1    key2=val2    # Dictionary variable
${TIMEOUT}        10s                       # Used with waits
```

### Keywords Section — Creating Reusable Keywords:

```robot
*** Keywords ***
# Simple keyword (no arguments)
Navigate To Login Page
    Click Element    ${NAV_SIGNUP_LOGIN_LINK}
    Wait Until Page Contains Element    ${LOGIN_HEADING}    timeout=10s

# Keyword with arguments
Login With Credentials
    [Arguments]    ${email}    ${password}
    Input Text    ${LOGIN_EMAIL_INPUT}    ${email}
    Input Text    ${LOGIN_PASSWORD_INPUT}    ${password}
    Click Button    ${LOGIN_BUTTON}

# Keyword that returns a value
Get Product Detail Name
    ${name}=    Get Text    ${PRODUCT_NAME}
    RETURN    ${name}

# Keyword with default argument
Click View Product
    [Arguments]    ${index}=1
    Click Element    xpath=(//a[contains(@href, 'product_details')])[${index}]
```

### Test Cases Section:

```robot
*** Test Cases ***
TC03 Login User With Incorrect Email And Password
    Navigate To Login Page
    Verify Login Page Visible
    Login With Credentials    ${INVALID_EMAIL}    ${INVALID_PASS}
    Verify Login Error Message
```

---

## 6. PAGE OBJECT MODEL (POM) EXPLAINED

### What is POM?
A **design pattern** where each web page gets its own class containing:
- **Locators** — element addresses on that page
- **Actions** — methods to interact with those elements

### Why POM?

| Without POM | With POM |
|-------------|----------|
| Locator duplicated in 10 tests | Locator defined ONCE in page class |
| UI change = fix 10 files | UI change = fix 1 file |
| Tests are hard to read | Tests read like plain English |
| No reusability | Full reusability |

### POM Hierarchy in This Project:

```
BasePage (base_page.py)
    |-- click(), enter_text(), get_text(), scroll(), hover()
    |
    |-- HomePage (home_page.py)         → Navbar, footer, subscription
    |-- LoginPage (login_page.py)       → Login + Signup forms
    |-- SignupPage (signup_page.py)     → Registration form
    |-- ProductsPage (products_page.py) → Product listing, search
    |-- ProductDetailPage               → Single product, review
    |-- CartPage (cart_page.py)         → Cart table, checkout
    |-- CheckoutPage (checkout_page.py) → Address, order review
    |-- PaymentPage (payment_page.py)   → Card payment
    |-- ContactPage (contact_page.py)   → Contact form
    |-- TestCasesPage                   → Test cases page
```

### How a Page Object Looks:

```python
from selenium.webdriver.common.by import By
from pages.base_page import BasePage

class LoginPage(BasePage):
    # Step 1: Define LOCATORS as class constants
    LOGIN_EMAIL    = (By.CSS_SELECTOR, "input[data-qa='login-email']")
    LOGIN_PASSWORD = (By.CSS_SELECTOR, "input[data-qa='login-password']")
    LOGIN_BTN      = (By.CSS_SELECTOR, "button[data-qa='login-button']")

    # Step 2: Define ACTIONS using inherited methods
    def login(self, email, password):
        self.enter_text(self.LOGIN_EMAIL, email)      # From BasePage
        self.enter_text(self.LOGIN_PASSWORD, password) # From BasePage
        self.click(self.LOGIN_BTN)                     # From BasePage
```

---

## 7. KEYWORD LAYERING ARCHITECTURE

### The 4 Layers:

```
Layer 1: TEST CASES (.robot files)
    "Login With Credentials  user@test.com  Pass123"
              ↓
Layer 2: KEYWORD RESOURCES (.resource files)
    Login With Credentials keyword → uses SeleniumLibrary + locator variables
              ↓
Layer 3: LOCATOR RESOURCES (.resource files)
    ${LOGIN_EMAIL_INPUT} = css=input[data-qa='login-email']
              ↓
Layer 4: PAGE OBJECTS (Python .py files)
    LoginPage.login() → self.enter_text(self.LOGIN_EMAIL, email)
```

### Why 4 Layers?

| Layer | Changes When | Who Maintains |
|-------|-------------|---------------|
| Tests | Business requirement changes | QA Lead |
| Keywords | Test workflow changes | Senior QA |
| Locators | UI element attributes change | QA Engineer |
| Page Objects | Page structure changes | Automation Engineer |

---

## 8. TEST DATA STRATEGY

### Dynamic vs Static Data:

```robot
# STATIC — same every run (for read-only operations)
${SEARCH_TERM}      Blue Top
${INVALID_EMAIL}    invalid_user@testmail.com

# DYNAMIC — unique every run (for create operations)
${unique_email}=    Generate Unique Email With Prefix    tc01_register
# Result: tc01_register_1711456789@testmail.com (timestamp-based)
```

### Why Dynamic Emails?
- **Run 1:** Creates account with `tc01_1711456700@testmail.com` → PASS
- **Run 2:** Creates account with `tc01_1711456800@testmail.com` → PASS
- Without dynamic: Run 2 fails with "Email already exists!"

### Test Data Location:

| Shared variables | `config/config.py` | `${BASE_URL}`, `${BROWSER}` |
| Test data | `config/test_data.py` | `${VALID_EMAIL}`, `${VALID_PASS}` |
| Dynamic values | Generated at runtime | `Generate Unique Email` keyword |

---

## 9. HOW TO RUN TESTS

### Step 1: Install Dependencies
```bash
pip3 install -r requirements.txt
```

### Step 2: Run Tests

#### Run ALL Tests:
```bash
robot --outputdir reports tests/
```

#### Run by Feature Module:
```bash
robot --outputdir reports tests/auth/
robot --outputdir reports tests/products/
robot --outputdir reports tests/cart/
robot --outputdir reports tests/checkout/
robot --outputdir reports tests/contact/
robot --outputdir reports tests/navigation/
robot --outputdir reports tests/subscription/
```

#### Run a Single Test File:
```bash
robot --outputdir reports tests/auth/TC01_register_user.robot
```

#### Run by Test Name Pattern:
```bash
robot --outputdir reports --test "TC01*" tests/
robot --outputdir reports --test "*login*" tests/
```

#### Run with Different Browser:
```bash
robot --outputdir reports --variable BROWSER:firefox tests/
robot --outputdir reports --variable BROWSER:chrome tests/
```

#### Run with Tags:
```bash
robot --outputdir reports --include smoke tests/
robot --outputdir reports --exclude slow tests/
robot --outputdir reports --include smoke --exclude slow tests/
```

#### Run Parallel (using Pabot):
```bash
pabot --outputdir reports tests/
pabot --outputdir reports tests/auth/
```

#### Dry Run (validates syntax without opening browser):
```bash
robot --dryrun --outputdir reports tests/
```

#### Run with Verbose Logging:
```bash
robot --outputdir reports --loglevel DEBUG tests/
```

### Step 3: View Reports

After running, open these files in your browser:

| File | What it shows |
|------|---------------|
| `reports/report.html` | Summary — pass/fail count, suite-level results |
| `reports/log.html` | Detailed — step-by-step execution with screenshots |
| `reports/output.xml` | Raw XML — used by CI/CD tools for parsing |

```bash
# Open report on Mac
open reports/report.html

# Open detailed log on Mac
open reports/log.html
```

### Quick Reference Table

| What you want | Command |
|---------------|---------|
| Run all tests | `robot --outputdir reports tests/` |
| Run auth tests only | `robot --outputdir reports tests/auth/` |
| Run one test file | `robot --outputdir reports tests/auth/TC01_register_user.robot` |
| Run by test name | `robot --outputdir reports --test "*login*" tests/` |
| Run on Firefox | `robot --outputdir reports --variable BROWSER:firefox tests/` |
| Run smoke tests | `robot --outputdir reports --include smoke tests/` |
| Run parallel | `pabot --outputdir reports tests/` |
| Dry run (no browser) | `robot --dryrun --outputdir reports tests/` |
| Debug mode | `robot --outputdir reports --loglevel DEBUG tests/` |
| Re-run failed tests | `robot --outputdir reports --rerunfailed reports/output.xml tests/` |

---

## 10. COMMON ROBOT FRAMEWORK COMMANDS REFERENCE

### SeleniumLibrary Keywords Used in This Project:

```robot
# --- Browser Management ---
Open Browser          ${URL}    ${BROWSER}       # Open browser and navigate
Close Browser                                     # Close current browser
Go To                 ${URL}                      # Navigate to URL
Title Should Be       Expected Title              # Assert page title

# --- Element Interaction ---
Click Element         ${locator}                  # Click an element
Click Button          ${locator}                  # Click a button
Input Text            ${locator}    ${text}       # Type into a field
Clear Element Text    ${locator}                  # Clear a field

# --- Dropdowns ---
Select From List By Value   ${locator}    ${value}    # Select by value attribute
Select From List By Label   ${locator}    ${label}    # Select by visible text

# --- Checkboxes ---
Select Checkbox       ${locator}                  # Check a checkbox
Uncheck Checkbox      ${locator}                  # Uncheck a checkbox

# --- Assertions ---
Page Should Contain           ${text}             # Assert text exists on page
Page Should Contain Element   ${locator}          # Assert element exists
Element Should Contain        ${locator}  ${text} # Assert element has text
Element Text Should Be        ${locator}  ${text} # Assert exact text match
Element Should Be Visible     ${locator}          # Assert element is visible

# --- Waits ---
Wait Until Page Contains              ${text}     timeout=10s
Wait Until Page Contains Element      ${locator}  timeout=10s
Wait Until Element Is Visible         ${locator}  timeout=10s
Wait Until Element Is Not Visible     ${locator}  timeout=10s
Set Selenium Implicit Wait            ${timeout}
Sleep                                 2s          # Hard wait (avoid when possible)

# --- Getting Values ---
${text}=    Get Text              ${locator}      # Get element text
${value}=   Get Element Attribute ${locator}  value  # Get attribute
${count}=   Get Element Count     ${locator}      # Count matching elements
${elements}=  Get WebElements     ${locator}      # Get list of elements

# --- Mouse Actions ---
Mouse Over            ${locator}                  # Hover over element
Scroll Element Into View  ${locator}              # Scroll to element

# --- JavaScript ---
Execute Javascript    window.scrollTo(0, document.body.scrollHeight)
Execute Javascript    arguments[0].click()    ARGUMENTS    ${element}

# --- Alerts ---
Handle Alert          action=ACCEPT               # Accept browser alert
Handle Alert          action=DISMISS              # Dismiss browser alert

# --- File Upload ---
Choose File           ${locator}    ${file_path}  # Upload a file

# --- Screenshots ---
Capture Page Screenshot                           # Save screenshot
```

### Robot Framework Built-in Keywords:

```robot
# --- Variables ---
${var}=    Set Variable        some value
Set Test Variable              ${MY_VAR}    value     # Available in current test
Set Suite Variable             ${MY_VAR}    value     # Available in current suite
Set Global Variable            ${MY_VAR}    value     # Available everywhere

# --- Assertions ---
Should Be Equal        ${actual}    ${expected}
Should Be Equal As Strings    ${actual}    ${expected}
Should Be Equal As Integers   ${actual}    ${expected}
Should Contain         ${string}    ${substring}
Should Contain         ${string}    ${sub}    ignore_case=True
Should Not Be Empty    ${value}
Should Be True         ${condition}

# --- Control Flow ---
IF    '${status}' == 'PASS'
    Log    Test passed
ELSE
    Log    Test failed
END

FOR    ${item}    IN    @{list}
    Log    ${item}
END

# --- Evaluate Python ---
${timestamp}=    Evaluate    str(int(__import__('time').time()))
${upper}=        Evaluate    "${text}".upper()

# --- Return ---
RETURN    ${value}

# --- Logging ---
Log    Message here
Log    ${variable}
Log To Console    Visible in terminal
```

---

## 11. INTERVIEW Q&A — FRAMEWORK & ARCHITECTURE

### Q1: What framework did you use and why?
**A:** We used a **keyword-driven framework** combining Robot Framework with Selenium WebDriver.
- **Robot Framework** — for keyword-driven tests that read like English, built-in HTML reporting, easy for non-technical stakeholders to understand.
- **Selenium (via SeleniumLibrary)** — for browser automation across Chrome, Firefox, etc.
- **Resource files** — for separating locators, keywords, and variables into reusable layers.

### Q2: How is your framework structured?
**A:** It follows a **4-layer architecture**:
1. **Test Layer** (`tests/`) — `.robot` files with test cases grouped by feature (auth, cart, checkout, etc.)
2. **Keyword Layer** (`resources/*_keywords.resource`) — reusable keywords like "Login With Credentials"
3. **Locator Layer** (`resources/locators/`) — element locators separated by page/feature
4. **Variable Layer** (`config/test_data.py`, `config/config.py`) — test data, URLs, credentials

### Q3: Why did you separate locators into their own files?
**A:** **Single Responsibility Principle.** When a UI element changes (e.g., a button ID changes), we update ONE locator file. The keywords and tests don't change at all. This reduces maintenance effort from touching 10+ files to touching 1 file.

### Q4: How do you handle test data?
**A:** Two strategies:
- **Static data** in `config/test_data.py` — for read-only operations (search terms, invalid credentials)
- **Dynamic data** generated at runtime using `Generate Unique Email With Prefix` keyword — uses Python timestamp to create unique emails, ensuring tests are **idempotent** (pass on every run)

### Q5: What makes your tests reusable/idempotent?
**A:** Three things:
1. **Dynamic emails** — every test run creates unique accounts using timestamp-based emails
2. **Self-cleanup** — every test that creates an account also deletes it at the end
3. **Self-provisioning** — tests that need a logged-in user create their own account first, don't depend on pre-existing data

### Q6: How many test cases do you have and what do they cover?
**A:** **26 test cases** across 7 feature modules:
- **Auth (5):** Register, valid login, invalid login, logout, duplicate email
- **Contact (1):** Contact Us form submission
- **Navigation (3):** Test cases page, scroll up with/without arrow
- **Products (5):** View all products, search, categories, brands, product review
- **Subscription (2):** Home page and cart page subscription
- **Cart (5):** Add to cart, verify quantity, remove, search+login persist, recommended items
- **Checkout (5):** Place order (3 flows), verify address, download invoice

### Q7: What is the role of `common.resource`?
**A:** It's the **shared foundation** containing:
- Browser setup/teardown keywords (headless Chrome configuration)
- Navbar locators used across all pages
- Cart modal locators (appears everywhere after add-to-cart)
- Utility keywords like `Generate Unique Email`
- Every test imports this file

### Q8: Why headless Chrome?
**A:** For CI/CD environments where there's no display. Headless mode:
- Runs faster (no rendering overhead)
- Works in Docker/CI servers without GUI
- Uses `--headless=new` flag with `--window-size=1920,1080` for consistent viewport

---

## 12. INTERVIEW Q&A — ROBOT FRAMEWORK SYNTAX

### Q9: What are the different sections in a Robot Framework file?
**A:**
- `*** Settings ***` — Library imports, Resource imports, Test Setup/Teardown
- `*** Variables ***` — Constants, locators, test data
- `*** Keywords ***` — Reusable keyword definitions
- `*** Test Cases ***` — Actual test scenarios (only in `.robot` files, not `.resource`)

### Q10: What is the difference between `.robot` and `.resource` files?
**A:**
- `.robot` — Contains `*** Test Cases ***` section, can be executed directly
- `.resource` — Contains only `*** Settings ***`, `*** Variables ***`, `*** Keywords ***` — meant to be imported by other files, cannot be executed directly

### Q11: How do you pass arguments to keywords?
**A:**
```robot
My Keyword
    [Arguments]    ${arg1}    ${arg2}    ${arg3}=default_value
    Log    ${arg1} ${arg2} ${arg3}
```
- `${arg1}`, `${arg2}` are required
- `${arg3}=default_value` is optional with a default

### Q12: How do you return values from keywords?
**A:**
```robot
Get Product Name
    ${name}=    Get Text    ${PRODUCT_NAME}
    RETURN    ${name}

# Usage:
${product}=    Get Product Name
```

### Q13: What is Test Setup and Test Teardown?
**A:**
- **Test Setup** — runs BEFORE each test case (e.g., open browser)
- **Test Teardown** — runs AFTER each test case, even if test fails (e.g., close browser)
```robot
Test Setup        Open Browser To Home Page
Test Teardown     Close Test Browser
```

### Q14: How do you use variables in Robot Framework?
**A:**
- `${SCALAR}` — single value (string, number)
- `@{LIST}` — list of values
- `&{DICT}` — key-value pairs
- Variables from `.resource` files are accessible when imported

### Q15: What is `Set Test Variable` vs `Set Suite Variable` vs `Set Global Variable`?
**A:**
- `Set Test Variable` — available only in the current test case
- `Set Suite Variable` — available in all tests within the current test suite file
- `Set Global Variable` — available across all test suites in the entire run

---

## 13. INTERVIEW Q&A — SELENIUM & LOCATORS

### Q16: What locator strategies do you use?
**A:** In priority order:
1. **data-qa attributes** — `css=input[data-qa='login-email']` — most stable
2. **ID** — `id=search_product` — unique and fast
3. **CSS Selectors** — `css=a.cart_quantity_delete` — flexible
4. **XPath** — `xpath=//a[contains(text(),'Logout')]` — for text matching

### Q17: When do you use XPath over CSS?
**A:**
- **XPath** when: matching by text content, navigating parent/ancestor, complex conditions
- **CSS** for everything else — it's faster and more readable
- Example needing XPath: `xpath=//b[contains(text(),'Brand')]/parent::p` (get parent of a child by text)

### Q18: How do you handle dynamic elements?
**A:**
- Use `contains()` in XPath: `xpath=//a[contains(@href, 'product_details')]`
- Use attribute selectors in CSS: `css=a[href*='product_details']`
- Use index for multiple matches: `xpath=(//div[@class='productinfo'])[1]`

### Q19: What waits do you use?
**A:**
- **Implicit Wait** — `Set Selenium Implicit Wait 10s` (global, set once)
- **Explicit Wait** — `Wait Until Element Is Visible ${locator} timeout=10s`
- **Hard Wait** — `Sleep 2s` (only when explicit wait isn't reliable, e.g., page transitions)
- We prefer explicit waits over `Sleep` for reliability.

### Q20: How do you handle elements behind overlays or modals?
**A:** In this project, the cart modal appears after adding to cart. We:
1. Wait for modal to be visible: `Wait Until Element Is Visible ${CART_MODAL_CONTINUE_SHOPPING_BTN} timeout=10s`
2. Use JavaScript click when element is intercepted: `Execute Javascript arguments[0].click() ARGUMENTS ${element}`

### Q21: How do you handle hover actions in headless mode?
**A:** Standard `Mouse Over` sometimes fails in headless. Our approach:
```robot
# Scroll to element first
Scroll Element Into View    xpath=(//div[@class='product-image-wrapper'])[1]
Sleep    1s
# Get element reference and use JavaScript click
${add_btn}=    Get WebElement    xpath=...//a[contains(@class,'add-to-cart')]
Execute Javascript    arguments[0].click()    ARGUMENTS    ${add_btn}
```

### Q22: What is StaleElementReferenceException and how do you handle it?
**A:** It occurs when the page refreshes/navigates and the element reference becomes invalid. We handle it by:
- Adding waits after page transitions (`Wait Until Page Contains Element`)
- Adding `Sleep` after critical navigation (e.g., after clicking "Continue" on account_created page)
- Re-finding elements after page changes

---

## 14. INTERVIEW Q&A — PAGE OBJECT MODEL

### Q23: What is Page Object Model?
**A:** A design pattern where:
- Each **web page** has a corresponding **Python class**
- The class contains **locators** (element addresses) and **methods** (actions on those elements)
- Tests never interact with raw Selenium — they call keyword methods
- If UI changes, only the locator resource file changes

### Q24: How are locators organized?
**A:** Locators are stored in separate `.resource` files under `resources/locators/`:
- `auth_locators.resource` — login, signup, registration form locators
- `products_locators.resource` — product listing, search locators
- `cart_locators.resource` — cart page locators
- Each locator is a Robot Framework variable: `${LOGIN_BUTTON}    css=button[data-qa='login-button']`

### Q25: How do you define locators in Robot Framework?
**A:** As variables in `.resource` files:
```robot
${LOGIN_EMAIL_INPUT}    css=input[data-qa='login-email']
```
SeleniumLibrary keywords like `Click Element`, `Input Text` accept these directly.

### Q26: How do locators, keywords, and tests connect?
**A:** Through Robot Framework's `Resource` import:
- Test file imports `auth_keywords.resource`
- `auth_keywords.resource` imports `auth_locators.resource`
- Keywords use locator variables to perform actions via SeleniumLibrary
- Tests call keywords — they never touch locators directly

---

## 15. INTERVIEW Q&A — TEST DESIGN & BEST PRACTICES

### Q27: How do you ensure tests are independent?
**A:** Each test:
- Opens a fresh browser (Test Setup)
- Creates its own test data (dynamic emails)
- Cleans up after itself (deletes accounts)
- Closes the browser (Test Teardown)
- No test depends on another test's state

### Q28: How do you handle test data across environments?
**A:** Through `config/config.py` — change `BASE_URL` for different environments, or use separate Python files.
```bash
robot --variable BASE_URL:https://staging.automationexercise.com tests/
```

### Q29: What is the test case naming convention?
**A:** `TC{number}_{descriptive_name}.robot` — e.g., `TC14_place_order_register_while_checkout.robot`. The TC number maps directly to the test case specification document.

### Q30: How do you organize tests?
**A:** By **feature module** — each feature has its own directory:
- `tests/auth/` — authentication tests
- `tests/cart/` — shopping cart tests
- `tests/checkout/` — checkout and payment tests
This allows running specific modules independently.

### Q31: What reporting does Robot Framework provide?
**A:** Three output files:
- `report.html` — High-level summary (pass/fail counts, suite stats)
- `log.html` — Detailed step-by-step execution with timestamps, screenshots on failure
- `output.xml` — Machine-readable XML for CI/CD integration

### Q32: How do you handle flaky tests?
**A:** In this project:
- Increased timeouts for external site operations (15-20s for account creation)
- Added `Sleep` after critical page transitions (login redirect, account creation)
- Used `Wait Until Page Contains` instead of element-specific waits for more reliability
- Used JavaScript clicks for overlay/hover elements in headless mode

---

## 16. INTERVIEW Q&A — REAL SCENARIO BASED

### Q33: A button's ID changed from "submit" to "submit-btn". What do you do?
**A:** Update ONE file — the locator resource:
```robot
# In resources/locators/auth_locators.resource
# Old: ${LOGIN_BUTTON}    css=#submit
# New: ${LOGIN_BUTTON}    css=#submit-btn
```
Zero changes in keywords or tests. This is the power of separating locators.

### Q34: A new field is added to the registration form. What do you do?
**A:** Three steps:
1. Add locator in `resources/locators/auth_locators.resource`
2. Add the field to `Fill Account Information` or `Fill Address Information` keyword in `auth_keywords.resource`
3. Add data variable in `config/test_data.py`

### Q35: How do you debug a failing test?
**A:**
1. Open `reports/log.html` — see exact step where it failed
2. Check the screenshot (auto-captured on failure)
3. Check the error message — usually tells you what element wasn't found
4. Run that single test in non-headless mode to see the browser
5. Check if locator still matches using browser DevTools (F12 → Elements)

### Q36: The website has ads/popups that block elements. How do you handle it?
**A:** In this project, we handle the Google annotation overlay by:
- Using JavaScript click instead of regular click: `Execute Javascript arguments[0].click()`
- Using `Scroll Element Into View` before clicking
- The ads don't block in headless mode (no ad network loads)

### Q37: How do you test the checkout flow that requires login?
**A:** Self-contained test approach:
1. Generate unique email at test start
2. Register a new account within the test
3. Add product to cart
4. Proceed to checkout
5. Fill payment and place order
6. Delete account at the end (cleanup)
This way the test works independently without pre-existing accounts.

### Q38: How do you verify an address in checkout matches what was entered during registration?
**A:** TC23 does exactly this:
1. Register with known address data (${FIRST_NAME}, ${ADDRESS1}, etc.)
2. Add product and go to checkout
3. Verify each address field:
```robot
Verify Delivery Address Details
    ...    Mr. ${FIRST_NAME} ${LAST_NAME}
    ...    ${COMPANY}
    ...    ${ADDRESS1}
    ...    ${CITY} ${STATE} ${ZIPCODE}
    ...    ${COUNTRY}
    ...    ${MOBILE}
```

### Q39: What is the difference between `Click Element` and `Click Button`?
**A:**
- `Click Element` — clicks any HTML element (link, div, span, button, etc.)
- `Click Button` — specifically clicks `<button>` or `<input type="submit">` elements
- We use `Click Button` for form submissions and `Click Element` for navigation links

### Q40: How do you handle file upload in tests?
**A:** Using SeleniumLibrary's `Choose File` keyword:
```robot
Choose File    css=input[name='upload_file']    ${CURDIR}/test_file.txt
```
The locator must point to an `<input type="file">` element.

---

## 17. TROUBLESHOOTING GUIDE

### Common Errors and Fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| `SessionNotCreatedException` | Chrome/ChromeDriver version mismatch | Update `webdriver-manager` or Chrome |
| `ElementNotInteractableException` | Element hidden or overlaid | Use `Scroll Element Into View` first |
| `StaleElementReferenceException` | Page refreshed, element ref invalid | Add `Wait Until` after navigation |
| `ElementClickInterceptedException` | Another element covers the target | Use `Execute Javascript` click |
| `NoSuchElementException` | Wrong locator or element not loaded | Check locator, add explicit wait |
| `TimeoutException` | Element didn't appear in time | Increase timeout value |
| `Select From List By Visible Text not found` | SeleniumLibrary version change | Use `Select From List By Label` |
| Case mismatch in assertion | Website uses UPPERCASE | Use `ignore_case=True` in Should Contain |

### Debug Commands:
```bash
# Run with verbose debug logging
robot --loglevel DEBUG --outputdir reports/ tests/

# Run single test to isolate issue
robot --outputdir reports/ --test "TC01*" tests/

# Run with screenshots on every step (not just failures)
robot --listener RobotFramework-DebugLibrary --outputdir reports/ tests/
```

---

## COMPLETE TEST CASE MAPPING

| TC # | Name | Feature | File |
|------|------|---------|------|
| TC01 | Register User | auth | `tests/auth/TC01_register_user.robot` |
| TC02 | Login Valid | auth | `tests/auth/TC02_login_valid.robot` |
| TC03 | Login Invalid | auth | `tests/auth/TC03_login_invalid.robot` |
| TC04 | Logout User | auth | `tests/auth/TC04_logout_user.robot` |
| TC05 | Register Existing Email | auth | `tests/auth/TC05_register_existing_email.robot` |
| TC06 | Contact Us Form | contact | `tests/contact/TC06_contact_us_form.robot` |
| TC07 | Verify Test Cases Page | navigation | `tests/navigation/TC07_verify_test_cases_page.robot` |
| TC08 | Verify All Products | products | `tests/products/TC08_verify_all_products.robot` |
| TC09 | Search Product | products | `tests/products/TC09_search_product.robot` |
| TC10 | Subscription Home Page | subscription | `tests/subscription/TC10_subscription_home_page.robot` |
| TC11 | Subscription Cart Page | subscription | `tests/subscription/TC11_subscription_cart_page.robot` |
| TC12 | Add Products to Cart | cart | `tests/cart/TC12_add_products_to_cart.robot` |
| TC13 | Verify Product Quantity | cart | `tests/cart/TC13_verify_product_quantity.robot` |
| TC14 | Place Order Register While Checkout | checkout | `tests/checkout/TC14_place_order_register_while_checkout.robot` |
| TC15 | Place Order Register Before Checkout | checkout | `tests/checkout/TC15_place_order_register_before_checkout.robot` |
| TC16 | Place Order Login Before Checkout | checkout | `tests/checkout/TC16_place_order_login_before_checkout.robot` |
| TC17 | Remove Products From Cart | cart | `tests/cart/TC17_remove_products_from_cart.robot` |
| TC18 | View Category Products | products | `tests/products/TC18_view_category_products.robot` |
| TC19 | View Brand Products | products | `tests/products/TC19_view_brand_products.robot` |
| TC20 | Search & Verify Cart After Login | cart | `tests/cart/TC20_search_and_verify_cart_after_login.robot` |
| TC21 | Add Product Review | products | `tests/products/TC21_add_product_review.robot` |
| TC22 | Add From Recommended Items | cart | `tests/cart/TC22_add_from_recommended_items.robot` |
| TC23 | Verify Address in Checkout | checkout | `tests/checkout/TC23_verify_address_in_checkout.robot` |
| TC24 | Download Invoice | checkout | `tests/checkout/TC24_download_invoice.robot` |
| TC25 | Scroll Up with Arrow | navigation | `tests/navigation/TC25_scroll_up_arrow.robot` |
| TC26 | Scroll Up without Arrow | navigation | `tests/navigation/TC26_scroll_up_no_arrow.robot` |

---

## 18. PARALLEL EXECUTION WITH PABOT

### 18.1 What is Pabot?

- **Pabot** = **Pa**rallel Ro**bot** — a parallel executor for Robot Framework
- Runs test suites/test cases in **separate processes simultaneously**
- Each process gets its **own browser instance**
- Merges results into a **single report** at the end
- Install: `pip install robotframework-pabot`

---

### 18.2 How Parallel Works in This Project

- **Sequential:** 26 tests run one after another (~7 minutes)
- **Parallel with 4 processes:** 4 tests run simultaneously (~1 min 53 sec = **3.7x faster**)
- Each process: opens its own Chrome browser → runs assigned tests → closes browser
- Pabot **automatically distributes** tests across processes

**Visual diagram:**

```
Process 0: TC01 → TC05 → TC08 → TC16 → TC24 → TC10
Process 1: TC02 → TC12 → TC22 → TC17 → TC25 → TC11
Process 2: TC03 → TC13 → TC14 → TC18 → TC19 → TC09
Process 3: TC04 → TC17 → TC15 → TC07 → TC06 → TC21
                    ↓ All finish ↓
            Pabot merges → report.html
```

---

### 18.3 Run Commands

```bash
# Basic parallel (4 processes)
pabot --processes 4 --outputdir reports/ tests/

# 7 processes (one per feature module)
pabot --processes 7 --outputdir reports/ tests/

# Split at test level (each test case = separate process)
pabot --processes 4 --testlevelsplit --outputdir reports/ tests/

# Parallel with specific module
pabot --processes 3 --outputdir reports/ tests/auth/ tests/cart/

# Sequential (normal robot) for comparison
robot --outputdir reports/ tests/
```

---

### 18.4 How Dependencies Work in Parallel

**Key rule: Tests must be INDEPENDENT. No test should depend on another test's state.**

#### WHY Our Tests Work in Parallel:

1. **Each test opens its own browser** — Test Setup creates a fresh browser per test
2. **Each test creates its own data** — Unique timestamp-based emails mean no conflicts
3. **Each test cleans up after itself** — Deletes accounts it created
4. **No shared state** — No test reads data written by another test

#### What Would BREAK Parallel Execution:

```
# BAD: TC02 depends on TC01 creating an account
TC01: Register user@test.com  → TC02: Login with user@test.com
# If TC02 runs before TC01 finishes → FAIL!

# GOOD: TC02 creates its own account
TC02: Register unique_email → Logout → Login unique_email → Delete
# Works regardless of TC01's status
```

#### Dependency Scenarios:

**Scenario 1: Shared Database State**
- Problem: TC01 creates account, TC05 tries to register same email → race condition
- Our solution: Each test uses `Generate Unique Email With Prefix` → no collisions

**Scenario 2: Shared Browser**
- Problem: Two tests try to use the same browser → chaos
- Our solution: Each test's `Test Setup` creates its OWN browser instance via `Open Browser To Home Page`

**Scenario 3: Test Order Dependency**
- Problem: TC14 expects cart items from TC12
- Our solution: TC14 adds its own items to cart within the test → fully self-contained

**Scenario 4: Shared File System**
- Problem: Two tests download invoice to same path → overwrite
- Pabot solution: Each process runs in isolation

---

### 18.5 Pabot Architecture Diagram

```
                    pabot (master)
                    /    |    |    \
               Proc-0  Proc-1  Proc-2  Proc-3
               Chrome  Chrome  Chrome  Chrome
               TC01    TC02    TC03    TC04
               TC05    TC12    TC13    TC17
               ...     ...     ...     ...
                    \    |    |    /
                     Merge Results
                     output.xml
                     report.html
                     log.html
```

---

### 18.6 Pabot vs Sequential — Performance Comparison

| Metric | Sequential (robot) | Parallel (pabot --processes 4) |
|--------|-------------------|-------------------------------|
| Total test time | ~7 min 1 sec | ~7 min 1 sec (same total) |
| Wall clock time | ~7 min 1 sec | ~1 min 53 sec |
| Speed improvement | 1x | 3.7x faster |
| Browser instances | 1 | 4 simultaneous |
| CPU usage | Low | Higher (4 Chrome processes) |
| Memory usage | Low | ~4x (4 browsers) |

---

### 18.7 When NOT to Use Parallel

- Tests that share a single user account and can't use unique data
- Tests that modify global application state (admin settings, feature flags)
- Tests hitting rate-limited APIs
- When debugging — sequential is easier to read logs

---

### 18.8 Pabot Configuration File (.pabotsuitenames)

- **Auto-generated** after first run
- Controls execution order for optimization
- Can be **manually edited** to group related tests
- Pabot uses this file on subsequent runs to optimize distribution

---

### 18.9 Interview Q&A about Parallel Execution

#### Q41: How do you run tests in parallel?
**A:** Using **Pabot** (Parallel Robot). Command: `pabot --processes 4 tests/`. It spawns 4 separate processes, each with its own browser, distributes tests, and merges results into a single `report.html`.

#### Q42: What is required for tests to run in parallel?
**A:** Tests must be **completely independent** — no shared state, no test order dependency, unique test data per test, own browser per test, and self-cleanup.

#### Q43: How do you handle test data conflicts in parallel execution?
**A:** We use **timestamp-based unique emails** (e.g., `tc01_1711456789@testmail.com`). Since timestamps are unique per millisecond, even parallel tests get different emails.

#### Q44: What happens if two parallel tests try to create the same account?
**A:** In our framework, this **CAN'T happen** because each test generates a unique email using `Generate Unique Email With Prefix` which includes the test case number AND timestamp.

#### Q45: Can you control which tests run on which process?
**A:** Yes, through the `.pabotsuitenames` file or by using the `--ordering` flag. You can group slow tests together or separate dependent tests.

---

## KEY TAKEAWAYS

1. **Separation of Concerns** — Locators, keywords, tests, and page objects are in separate files
2. **Reusability** — Write once, use in all 26 tests
3. **Maintainability** — UI change = change 1 locator file, not 26 test files
4. **Readability** — Robot tests read like plain English
5. **Idempotency** — Every test can run unlimited times without failure
6. **Self-Cleanup** — Tests create and delete their own test data
7. **Scalability** — Adding a new test case = add 1 `.robot` file, reuse existing keywords
8. **Parallel Execution** — Tests run 3.7x faster with Pabot because they are fully independent with unique data, own browsers, and self-cleanup
