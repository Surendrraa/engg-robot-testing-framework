*** Settings ***
Documentation    Common locators shared across all pages - navbar, footer, subscription,
...              scroll, recommended items, and cart modal.
Library           SeleniumLibrary
Library           String
Variables         ../config/config.py
Variables         ../config/test_data.py

*** Variables ***
${SCREENSHOT_DIR}                       ${CURDIR}${/}..${/}reports${/}screenshots
# ---------- Navbar ----------
${NAV_HOME_LINK}                        xpath=//a[contains(text(),'Home')]
${NAV_PRODUCTS_LINK}                    xpath=//a[contains(text(),'Products')]
${NAV_CART_LINK}                        xpath=//a[contains(text(),'Cart')]
${NAV_SIGNUP_LOGIN_LINK}                xpath=//a[contains(text(),'Signup / Login')]
${NAV_TEST_CASES_LINK}                  xpath=//a[contains(text(),'Test Cases')]
${NAV_API_TESTING_LINK}                 xpath=//a[contains(text(),'API Testing')]
${NAV_CONTACT_US_LINK}                  xpath=//a[contains(text(),'Contact us')]
${NAV_LOGOUT_LINK}                      xpath=//a[contains(text(),'Logout')]
${NAV_DELETE_ACCOUNT_LINK}              xpath=//a[contains(text(),'Delete Account')]
${NAV_LOGGED_IN_AS_TEXT}                css=li a b

# Navbar URLs
${NAV_HOME_URL}                         /
${NAV_PRODUCTS_URL}                     /products
${NAV_CART_URL}                         /view_cart
${NAV_SIGNUP_LOGIN_URL}                 /login
${NAV_TEST_CASES_URL}                   /test_cases
${NAV_API_TESTING_URL}                  /api_list
${NAV_CONTACT_US_URL}                   /contact_us
${NAV_LOGOUT_URL}                       /logout
${NAV_DELETE_ACCOUNT_URL}               /delete_account

# ---------- Footer / Subscription ----------
${FOOTER_SUBSCRIPTION_HEADING}          css=.footer-widget h2
${FOOTER_SUBSCRIPTION_EMAIL_INPUT}      id=susbscribe_email
${FOOTER_SUBSCRIBE_BUTTON}              id=subscribe
${FOOTER_SUBSCRIPTION_SUCCESS_MSG}      css=#success-subscribe div.alert-success

# ---------- Scroll ----------
${SCROLL_UP_BUTTON}                     id=scrollUp

# ---------- Recommended Items ----------
${RECOMMENDED_SECTION_HEADING}          css=.recommended_items h2
${RECOMMENDED_CAROUSEL}                 id=recommended-item-carousel
${RECOMMENDED_PRODUCT_ADD_TO_CART}      css=.recommended_items .add-to-cart

# ---------- Cart Modal (appears after adding to cart) ----------
${CART_MODAL_CONTAINER}                 id=cartModal
${CART_MODAL_TITLE}                     css=#cartModal .modal-title
${CART_MODAL_BODY_TEXT}                  css=#cartModal .modal-body p
${CART_MODAL_VIEW_CART_LINK}            css=#cartModal a[href='/view_cart']
${CART_MODAL_CONTINUE_SHOPPING_BTN}     css=#cartModal .close-modal

*** Keywords ***
Open Browser To Home Page
    # Normalize HEADLESS so CLI overrides like --variable HEADLESS:False work reliably.
    ${is_headless}=    Evaluate    str(${HEADLESS}).strip().lower() in ["true", "1", "yes", "on"]
    Log    Starting browser (Headless: ${is_headless}) to: ${BASE_URL}
    ${chrome_options}=    Evaluate    selenium.webdriver.ChromeOptions()    modules=selenium.webdriver
    IF    ${is_headless}
        Evaluate    $chrome_options.add_argument("--headless=new")
    END
    Evaluate    $chrome_options.add_argument("--no-sandbox")
    Evaluate    $chrome_options.add_argument("--disable-dev-shm-usage")
    Evaluate    $chrome_options.add_argument("--disable-gpu")
    Evaluate    $chrome_options.add_argument("--window-size=1920,1080")
    # More stable transport in Linux/WSL headless environments
    Evaluate    $chrome_options.add_argument("--remote-debugging-pipe")
    # Additional flags for Linux stability and parallel execution
    Evaluate    $chrome_options.add_argument("--disable-extensions")
    # Use incognito to avoid persistent profile locking issues
    Evaluate    $chrome_options.add_argument("--incognito")
    Create Webdriver    Chrome    options=${chrome_options}
    Set Screenshot Directory    ${SCREENSHOT_DIR}
    Register Keyword To Run On Failure    Capture Failure Screenshot
    Go To    ${BASE_URL}
    Set Selenium Implicit Wait    ${TIMEOUT}
    Title Should Be    Automation Exercise

Close Test Browser
    Register Keyword To Run On Failure    NONE
    Close Browser

Capture Failure Screenshot
    [Documentation]    Capture screenshot with failed test case name for easier traceability in reports.
    ${safe_test_name}=    Evaluate    __import__("re").sub(r"[^A-Za-z0-9._-]+", "_", """${TEST NAME}""").strip("_")
    ${safe_suite_name}=    Evaluate    __import__("re").sub(r"[^A-Za-z0-9._-]+", "_", """${SUITE NAME}""").strip("_")
    ${ts}=    Evaluate    str(int(__import__("time").time()*1000))
    Capture Page Screenshot    ${safe_suite_name}__${safe_test_name}__${ts}.png

Generate Unique Email
    [Documentation]    Generates a unique email using timestamp to avoid conflicts on re-run
    ${timestamp}=    Evaluate    str(int(__import__('time').time()))
    ${email}=    Set Variable    testuser_${timestamp}@testmail.com
    RETURN    ${email}

Generate Unique Email With Prefix
    [Arguments]    ${prefix}
    ${timestamp}=    Evaluate    str(int(__import__('time').time()))
    ${email}=    Set Variable    ${prefix}_${timestamp}@testmail.com
    RETURN    ${email}

Register Fresh Account And Login
    [Documentation]    Creates a new account, completes registration, and returns to home page logged in.
    ...                Used by tests that need a pre-existing logged-in state.
    [Arguments]    ${name}    ${email}    ${password}    ${first}    ${last}    ${company}    ${address}    ${address2}    ${country}    ${state}    ${city}    ${zip}    ${mobile}
    Navigate To Login Page
    Enter Signup Name And Email    ${name}    ${email}
    Fill Account Information    ${password}    15    March    1995
    Fill Address Information    ${first}    ${last}    ${company}    ${address}    ${address2}    ${country}    ${state}    ${city}    ${zip}    ${mobile}
    Click Create Account
    Click Continue After Account Created

Cleanup Test User
    [Documentation]    Deletes the current account if logged in.
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    ${NAV_DELETE_ACCOUNT_LINK}
    IF    ${status}
        # CI can show ad overlays/iframes that intercept native click on top navbar links.
        ${clicked}=    Run Keyword And Return Status    Click Element    ${NAV_DELETE_ACCOUNT_LINK}
        IF    not ${clicked}
            Log    Native click failed on Delete Account; trying JS click fallback.    level=WARN
            Execute JavaScript    document.querySelector("a[href='/delete_account']").click()
        END
        ${deleted}=    Run Keyword And Return Status    Wait Until Page Contains    Account Deleted    timeout=45s
        IF    not ${deleted}
            Log    Account deletion confirmation not visible; continuing without failing teardown.    level=WARN
        END
    ELSE
        Log    Delete Account link not found, skipping cleanup.    level=DEBUG
    END
