# Page Object Model (POM) — How It Works

---

## What is POM?

One page = One class. All elements and actions of that page live inside that class.
Tests don't touch elements directly — they talk to page classes.

---

## Why POM?

| Without POM | With POM |
|---|---|
| Login steps written in 50 test files | Login steps written in 1 file (LoginPage) |
| Locator changes → fix 50 places | Locator changes → fix 1 place |
| Tests are long and messy | Tests read like English |
| Hard to maintain | Easy to maintain |

---

## Micro Steps — How POM Works

```
Step 1: Create a class for each page
        LoginPage, DashboardPage, CartPage, CheckoutPage

Step 2: Store all locators inside the class
        USERNAME = (By.ID, "username")
        PASSWORD = (By.ID, "password")
        LOGIN_BTN = (By.ID, "loginBtn")

Step 3: Create methods for each action on that page
        enter_username()
        enter_password()
        click_login()

Step 4: Method returns the NEXT page object
        click_login() → returns DashboardPage

Step 5: Test uses page objects — never touches locators directly
        login_page.login_as("admin", "pass")
        dashboard.verify_welcome("admin")
```

---

## Flow Diagram

```
TEST FILE
   │
   │  calls
   ▼
LOGIN PAGE (class)
   │── locators: username, password, login button
   │── methods: enter_username(), enter_password(), click_login()
   │
   │  click_login() returns
   ▼
DASHBOARD PAGE (class)
   │── locators: welcome message, menu, logout button
   │── methods: get_welcome_text(), logout()
   │
   │  logout() returns
   ▼
LOGIN PAGE (class) ← back to login
```

---

## Folder Structure

```
project/
├── pages/                  ← All page classes live here
│   ├── base_page.py        ← Common methods (click, type, wait)
│   ├── login_page.py       ← Login page elements & actions
│   ├── dashboard_page.py   ← Dashboard elements & actions
│   └── cart_page.py        ← Cart elements & actions
│
├── tests/                  ← All test files live here
│   ├── test_login.py
│   ├── test_dashboard.py
│   └── test_cart.py
│
├── utils/                  ← Helpers
│   ├── config.py           ← URLs, credentials, settings
│   └── helpers.py          ← Random data, screenshots
│
└── conftest.py             ← Fixtures (browser setup/teardown)
```

---

## How Each File Looks (Simple View)

### base_page.py — Parent of all pages

```
BasePage
   ├── __init__(driver)         ← receives browser driver
   ├── click(locator)           ← click any element
   ├── type_text(locator, text) ← type into any field
   ├── get_text(locator)        ← read text from element
   ├── wait_for_visible(locator)← wait until element shows up
   └── take_screenshot(name)    ← capture screen on failure
```

### login_page.py — Inherits from BasePage

```
LoginPage (inherits BasePage)
   ├── LOCATORS:
   │     USERNAME = (By.ID, "username")
   │     PASSWORD = (By.ID, "password")
   │     LOGIN_BTN = (By.ID, "loginBtn")
   │     ERROR_MSG = (By.CLASS_NAME, "error")
   │
   ├── METHODS:
   │     open()              → navigates to login URL
   │     enter_username(user)→ types into username field
   │     enter_password(pwd) → types into password field
   │     click_login()       → clicks login, returns DashboardPage
   │     login_as(user, pwd) → does all 3 steps in one call
   │     get_error_message() → returns error text
```

### test_login.py — Uses page objects only

```
Test: Successful Login
   1. Create LoginPage object
   2. Call login_page.open()
   3. Call dashboard = login_page.login_as("admin", "admin123")
   4. Assert dashboard.get_welcome_text() contains "admin"

Test: Invalid Password
   1. Create LoginPage object
   2. Call login_page.open()
   3. Call login_page.login_as("admin", "wrong")
   4. Assert login_page.get_error_message() == "Invalid credentials"
```

---

## The Flow — Step by Step

```
1. Test starts
       │
2. Fixture creates browser (Chrome/Firefox)
       │
3. Test creates LoginPage(browser)
       │
4. Test calls login_page.open()
       │   └── internally: browser.get("https://app.com/login")
       │
5. Test calls login_page.login_as("admin", "admin123")
       │   └── internally:
       │         ├── type "admin" into USERNAME field
       │         ├── type "admin123" into PASSWORD field
       │         └── click LOGIN_BTN
       │
6. login_as() returns DashboardPage(browser)
       │
7. Test calls dashboard.get_welcome_text()
       │   └── internally: reads text from WELCOME_MSG element
       │
8. Test asserts "admin" is in the welcome text
       │
9. Fixture closes browser (cleanup)
       │
10. PASS ✓ or FAIL ✗
```

---

## Key Rules of POM

| Rule | Why |
|---|---|
| Locators stay inside page class | If UI changes, fix one file only |
| Tests never use `find_element` directly | Tests should read like English |
| Each method does ONE action | Small, reusable, easy to debug |
| Method returns next page object | Enables chaining: `login_page.login() → dashboard` |
| BasePage has common methods | Write click/type/wait once, every page inherits |
| No assertions inside page classes | Pages describe actions, tests decide pass/fail |

---

## Real-Life Scenario — E-Commerce Flow

```
Test: User buys a product

1. LoginPage.open()
2. dashboard = LoginPage.login_as("john", "pass123")
3. search_results = dashboard.search("laptop")
4. product = search_results.click_product("Dell Laptop")
5. product.add_to_cart()
6. cart = product.go_to_cart()
7. checkout = cart.proceed_to_checkout()
8. checkout.fill_address("123 Main St")
9. confirmation = checkout.place_order()
10. assert confirmation.get_order_status() == "Order Placed"

Pages involved:
LoginPage → DashboardPage → SearchResultsPage → ProductPage → CartPage → CheckoutPage → ConfirmationPage

Each page is a separate class.
Each step is a single method call.
The test reads like a user story.
```

---

## One Line Summary

> **POM = Each page is a class. Locators and actions inside the class. Tests only call methods. UI changes → fix one class, not 50 tests.**
