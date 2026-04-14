# 🗂️ Page Object Model (POM) — Robot Framework + Python
## Project: https://www.automationexercise.com

---

## 📁 Folder Structure

```
AutomationExercise_POM/
│
├── pages/                              # Page Object classes — one file per page
│   ├── __init__.py
│   ├── base_page.py                    # Common methods (click, type, wait, scroll)
│   ├── home_page.py                    # TC10, TC22, TC25, TC26
│   ├── login_page.py                   # TC2, TC3, TC4, TC5
│   ├── signup_page.py                  # TC1, TC5
│   ├── products_page.py                # TC8, TC9, TC18, TC19, TC20
│   ├── product_detail_page.py          # TC8, TC13, TC21
│   ├── cart_page.py                    # TC11, TC12, TC13, TC17, TC20
│   ├── checkout_page.py                # TC14, TC15, TC16, TC23
│   ├── payment_page.py                 # TC14, TC15, TC16, TC24
│   ├── contact_page.py                 # TC6
│   └── test_cases_page.py             # TC7
│
├── resources/                          # Robot Framework keyword resource files
│   ├── common.resource                 # Browser open/close, shared keywords
│   ├── common.resource                 # Browser open/close, shared keywords
│   ├── auth_keywords.resource          # Login, signup, logout keywords
│   ├── product_keywords.resource       # Search, view, filter keywords
│   ├── cart_keywords.resource          # Add, remove, verify cart keywords
│   ├── checkout_keywords.resource      # Checkout, payment, order keywords
│   └── subscription_keywords.resource  # Subscription form keywords
│
├── tests/                              # Robot Framework test suites
│   │
│   ├── auth/                           # TC1 to TC5
│   │   ├── TC01_register_user.robot
│   │   ├── TC02_login_valid.robot
│   │   ├── TC03_login_invalid.robot
│   │   ├── TC04_logout_user.robot
│   │   └── TC05_register_existing_email.robot
│   │
│   ├── contact/                        # TC6
│   │   └── TC06_contact_us_form.robot
│   │
│   ├── navigation/                     # TC7, TC25, TC26
│   │   ├── TC07_verify_test_cases_page.robot
│   │   ├── TC25_scroll_up_arrow.robot
│   │   └── TC26_scroll_up_no_arrow.robot
│   │
│   ├── products/                       # TC8, TC9, TC18, TC19, TC21
│   │   ├── TC08_verify_all_products.robot
│   │   ├── TC09_search_product.robot
│   │   ├── TC18_view_category_products.robot
│   │   ├── TC19_view_brand_products.robot
│   │   └── TC21_add_product_review.robot
│   │
│   ├── cart/                           # TC12, TC13, TC17, TC20, TC22
│   │   ├── TC12_add_products_to_cart.robot
│   │   ├── TC13_verify_product_quantity.robot
│   │   ├── TC17_remove_products_from_cart.robot
│   │   ├── TC20_search_and_verify_cart_after_login.robot
│   │   └── TC22_add_from_recommended_items.robot
│   │
│   ├── subscription/                   # TC10, TC11
│   │   ├── TC10_subscription_home_page.robot
│   │   └── TC11_subscription_cart_page.robot
│   │
│   └── checkout/                       # TC14, TC15, TC16, TC23, TC24
│       ├── TC14_place_order_register_while_checkout.robot
│       ├── TC15_place_order_register_before_checkout.robot
│       ├── TC16_place_order_login_before_checkout.robot
│       ├── TC23_verify_address_in_checkout.robot
│       └── TC24_download_invoice.robot
│
├── config/                             # Project configuration
│   ├── config.py                       # Base URL, browser, timeout settings
│   └── test_data.py                    # Usernames, passwords, card details
│
├── utils/                              # Helper utilities
│   ├── __init__.py
│   ├── custom_keywords.py              # Custom Python keywords for Robot
│   └── logger.py                       # Logging helper
│
├── drivers/                            # Browser drivers
│   └── chromedriver.exe
│
├── reports/                            # Auto-generated after test run
│   ├── log.html
│   ├── report.html
│   └── output.xml
│
├── requirements.txt
└── README.md
```

---

## 🗺️ Test Case to File Mapping

| TC # | Test Case Name | Test File | Page Objects Used |
|------|---------------|-----------|-------------------|
| TC01 | Register User | `auth/TC01_register_user.robot` | `home_page`, `login_page`, `signup_page` |
| TC02 | Login Valid | `auth/TC02_login_valid.robot` | `home_page`, `login_page` |
| TC03 | Login Invalid | `auth/TC03_login_invalid.robot` | `home_page`, `login_page` |
| TC04 | Logout User | `auth/TC04_logout_user.robot` | `home_page`, `login_page` |
| TC05 | Register Existing Email | `auth/TC05_register_existing_email.robot` | `home_page`, `login_page`, `signup_page` |
| TC06 | Contact Us Form | `contact/TC06_contact_us_form.robot` | `home_page`, `contact_page` |
| TC07 | Verify Test Cases Page | `navigation/TC07_verify_test_cases_page.robot` | `home_page`, `test_cases_page` |
| TC08 | Verify All Products | `products/TC08_verify_all_products.robot` | `home_page`, `products_page`, `product_detail_page` |
| TC09 | Search Product | `products/TC09_search_product.robot` | `home_page`, `products_page` |
| TC10 | Subscription Home Page | `subscription/TC10_subscription_home_page.robot` | `home_page` |
| TC11 | Subscription Cart Page | `subscription/TC11_subscription_cart_page.robot` | `home_page`, `cart_page` |
| TC12 | Add Products to Cart | `cart/TC12_add_products_to_cart.robot` | `home_page`, `products_page`, `cart_page` |
| TC13 | Verify Product Quantity | `cart/TC13_verify_product_quantity.robot` | `home_page`, `product_detail_page`, `cart_page` |
| TC14 | Place Order Register While Checkout | `checkout/TC14_place_order_register_while_checkout.robot` | `cart_page`, `login_page`, `signup_page`, `checkout_page`, `payment_page` |
| TC15 | Place Order Register Before Checkout | `checkout/TC15_place_order_register_before_checkout.robot` | `login_page`, `signup_page`, `cart_page`, `checkout_page`, `payment_page` |
| TC16 | Place Order Login Before Checkout | `checkout/TC16_place_order_login_before_checkout.robot` | `login_page`, `cart_page`, `checkout_page`, `payment_page` |
| TC17 | Remove Products From Cart | `cart/TC17_remove_products_from_cart.robot` | `home_page`, `cart_page` |
| TC18 | View Category Products | `products/TC18_view_category_products.robot` | `home_page`, `products_page` |
| TC19 | View Brand Products | `products/TC19_view_brand_products.robot` | `home_page`, `products_page` |
| TC20 | Search & Verify Cart After Login | `cart/TC20_search_and_verify_cart_after_login.robot` | `products_page`, `cart_page`, `login_page` |
| TC21 | Add Product Review | `products/TC21_add_product_review.robot` | `products_page`, `product_detail_page` |
| TC22 | Add from Recommended Items | `cart/TC22_add_from_recommended_items.robot` | `home_page`, `cart_page` |
| TC23 | Verify Address in Checkout | `checkout/TC23_verify_address_in_checkout.robot` | `login_page`, `signup_page`, `cart_page`, `checkout_page` |
| TC24 | Download Invoice | `checkout/TC24_download_invoice.robot` | `cart_page`, `checkout_page`, `payment_page` |
| TC25 | Scroll Up with Arrow | `navigation/TC25_scroll_up_arrow.robot` | `home_page` |
| TC26 | Scroll Up without Arrow | `navigation/TC26_scroll_up_no_arrow.robot` | `home_page` |

---

## 📄 Key File Contents

### `pages/base_page.py`
```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.action_chains import ActionChains

class BasePage:
    def __init__(self, driver):
        self.driver = driver
        self.wait = WebDriverWait(driver, 10)

    def click(self, locator):
        self.wait.until(EC.element_to_be_clickable(locator)).click()

    def enter_text(self, locator, text):
        element = self.wait.until(EC.visibility_of_element_located(locator))
        element.clear()
        element.send_keys(text)

    def get_text(self, locator):
        return self.wait.until(EC.visibility_of_element_located(locator)).text

    def is_visible(self, locator):
        return self.wait.until(EC.visibility_of_element_located(locator)).is_displayed()

    def scroll_to_bottom(self):
        self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")

    def scroll_to_top(self):
        self.driver.execute_script("window.scrollTo(0, 0);")

    def hover(self, locator):
        element = self.wait.until(EC.visibility_of_element_located(locator))
        ActionChains(self.driver).move_to_element(element).perform()
```

---

### `pages/login_page.py`
```python
from selenium.webdriver.common.by import By
from pages.base_page import BasePage

class LoginPage(BasePage):
    # Locators
    LOGIN_EMAIL    = (By.CSS_SELECTOR, "input[data-qa='login-email']")
    LOGIN_PASSWORD = (By.CSS_SELECTOR, "input[data-qa='login-password']")
    LOGIN_BTN      = (By.CSS_SELECTOR, "button[data-qa='login-button']")
    ERROR_MSG      = (By.CSS_SELECTOR, "p[style='color: red;']")
    LOGOUT_LINK    = (By.LINK_TEXT, "Logout")
    LOGGED_IN_TEXT = (By.CSS_SELECTOR, "li a b")

    # Actions
    def login(self, email, password):
        self.enter_text(self.LOGIN_EMAIL, email)
        self.enter_text(self.LOGIN_PASSWORD, password)
        self.click(self.LOGIN_BTN)

    def logout(self):
        self.click(self.LOGOUT_LINK)

    def get_error_message(self):
        return self.get_text(self.ERROR_MSG)

    def get_logged_in_username(self):
        return self.get_text(self.LOGGED_IN_TEXT)
```

---

### `pages/products_page.py`
```python
from selenium.webdriver.common.by import By
from pages.base_page import BasePage

class ProductsPage(BasePage):
    SEARCH_INPUT   = (By.ID, "search_product")
    SEARCH_BTN     = (By.ID, "submit_search")
    PRODUCT_LIST   = (By.CSS_SELECTOR, ".productinfo")
    VIEW_PRODUCT   = (By.LINK_TEXT, "View Product")
    SEARCHED_TITLE = (By.CSS_SELECTOR, "h2.title")

    def search_product(self, product_name):
        self.enter_text(self.SEARCH_INPUT, product_name)
        self.click(self.SEARCH_BTN)

    def click_view_product(self):
        self.click(self.VIEW_PRODUCT)

    def is_search_results_visible(self):
        return self.is_visible(self.SEARCHED_TITLE)
```

---

### `pages/cart_page.py`
```python
from selenium.webdriver.common.by import By
from pages.base_page import BasePage

class CartPage(BasePage):
    CART_ITEMS         = (By.CSS_SELECTOR, "tr.cart_menu")
    DELETE_BTN         = (By.CSS_SELECTOR, "a.cart_quantity_delete")
    PROCEED_CHECKOUT   = (By.LINK_TEXT, "Proceed To Checkout")
    SUBSCRIPTION_EMAIL = (By.ID, "susbscribe_email")
    SUBSCRIBE_BTN      = (By.ID, "subscribe")
    SUCCESS_MSG        = (By.CSS_SELECTOR, "#success-subscribe div.alert-success")

    def remove_product(self):
        self.click(self.DELETE_BTN)

    def proceed_to_checkout(self):
        self.click(self.PROCEED_CHECKOUT)

    def subscribe(self, email):
        self.scroll_to_bottom()
        self.enter_text(self.SUBSCRIPTION_EMAIL, email)
        self.click(self.SUBSCRIBE_BTN)

    def get_subscription_success_message(self):
        return self.get_text(self.SUCCESS_MSG)
```

---

### `config/test_data.py`
```python
# Valid user credentials
VALID_EMAIL    = "testuser@example.com"
VALID_PASS     = "Test@1234"
INVALID_EMAIL  = "wrong@example.com"
INVALID_PASS   = "wrongpass"
SEARCH_TERM    = "Blue Top"
```

---

### `resources/auth_keywords.resource`
```robot
*** Settings ***
Library     SeleniumLibrary
Variables   ../config/config.py
Variables   ../config/test_data.py

*** Keywords ***
Open Browser To Home Page
    Open Browser    ${BASE_URL}    ${BROWSER}
    Maximize Browser Window
    Title Should Be    Automation Exercise

Navigate To Login Page
    Click Element    xpath=//a[contains(text(),'Signup / Login')]

Login With Credentials
    [Arguments]    ${email}    ${password}
    Input Text     css=input[data-qa='login-email']       ${email}
    Input Text     css=input[data-qa='login-password']    ${password}
    Click Button   css=button[data-qa='login-button']

Verify Logged In As
    [Arguments]    ${username}
    Page Should Contain    Logged in as ${username}

Logout From Application
    Click Element    xpath=//a[contains(text(),'Logout')]
    Page Should Contain    Login to your account
```

---

### `tests/auth/TC02_login_valid.robot`
```robot
*** Settings ***
Resource          ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Test Setup        Open Browser To Home Page
Test Teardown     Close Browser

*** Test Cases ***
TC02 Login User With Correct Email And Password
    Navigate To Login Page
    Page Should Contain    Login to your account
    Login With Credentials    ${VALID_EMAIL}    ${VALID_PASS}
    Verify Logged In As    TestUser
    Click Element    xpath=//a[contains(text(),'Delete Account')]
    Page Should Contain    ACCOUNT DELETED!
```

---

### `tests/products/TC09_search_product.robot`
```robot
*** Settings ***
Resource          ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Test Setup        Open Browser To Home Page
Test Teardown     Close Browser

*** Test Cases ***
TC09 Search Product
    Click Element     xpath=//a[contains(text(),'Products')]
    Page Should Contain    ALL PRODUCTS
    Input Text        id=search_product    ${SEARCH_TERM}
    Click Button      id=submit_search
    Page Should Contain    SEARCHED PRODUCTS
    Page Should Contain Element    css=.productinfo
```

---

### `config/config.py`
```python
BASE_URL      = "https://www.automationexercise.com"
BROWSER       = "chrome"
TIMEOUT       = 10
HEADLESS      = False
IMPLICIT_WAIT = 10
```

---

### `config/test_data.py`
```python
# Valid user credentials
VALID_EMAIL    = "testuser@example.com"
VALID_PASSWORD = "Test@1234"

# Invalid credentials
INVALID_EMAIL    = "wrong@example.com"
INVALID_PASSWORD = "wrongpass"

# Signup details
FIRST_NAME = "Test"
LAST_NAME  = "User"
COMPANY    = "TestCorp"
ADDRESS    = "123 Main Street"
COUNTRY    = "India"
STATE      = "Karnataka"
CITY       = "Bengaluru"
ZIPCODE    = "560001"
MOBILE     = "9876543210"

# Payment details
CARD_NAME   = "Test User"
CARD_NUMBER = "4111111111111111"
CARD_CVC    = "123"
CARD_EXPIRY = "12/26"

# Search
SEARCH_TERM = "Blue Top"
```

---

### `requirements.txt`
```
robotframework==6.1.1
robotframework-seleniumlibrary==6.1.0
selenium==4.15.2
webdriver-manager==4.0.1
```

---

## ▶️ How to Run Tests

```bash
# Install all dependencies
pip install -r requirements.txt

# Run ALL 26 test cases
robot --outputdir reports/ tests/

# Run a specific module
robot --outputdir reports/ tests/auth/
robot --outputdir reports/ tests/products/
robot --outputdir reports/ tests/cart/
robot --outputdir reports/ tests/checkout/

# Run a single test case
robot --outputdir reports/ tests/auth/TC02_login_valid.robot

# Run with specific browser
robot --variable BROWSER:firefox --outputdir reports/ tests/

# Run with tags
robot --include smoke --outputdir reports/ tests/
```

---

## 🔑 POM Key Principles

| Principle | Description |
|---|---|
| **Separation of concerns** | Locators and actions in `pages/`, keywords in `resources/`, test logic in `tests/` |
| **Reusability** | `BasePage` methods reused across all 10 page objects |
| **Maintainability** | Change a locator in one place — all 26 test cases update automatically |
| **Readability** | Robot test cases read like plain English using keyword abstraction |
| **Scalability** | Tests grouped by feature module — easy to add new test cases |
| **Traceability** | Each `.robot` file is named with TC number — maps directly to the 26 test cases on the website |