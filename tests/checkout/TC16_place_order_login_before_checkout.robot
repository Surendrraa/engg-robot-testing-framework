*** Settings ***
Documentation     TC16 - Place Order Login Before Checkout
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/auth_keywords.resource
Resource          ../../resources/product_keywords.resource
Resource          ../../resources/cart_keywords.resource
Resource          ../../resources/checkout_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC16 Place Order Login Before Checkout
    [Tags]    skip
    # Register a fresh account first
    ${unique_email}=    Generate Unique Email With Prefix    tc16_checkout
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Logout and login back to simulate "login before checkout"
    Logout From Application
    Navigate To Login Page
    Login With Credentials    ${unique_email}    ${VALID_PASS}
    Verify Logged In As    ${SIGNUP_NAME}
    # Add product and checkout
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    Navigate To Cart Page
    Verify Cart Page Visible
    Click Proceed To Checkout
    Verify Checkout Page Visible
    Enter Order Comment    Login before checkout test
    Click Place Order
    Fill Payment Details    ${CARD_NAME}    ${CARD_NUMBER}    ${CARD_CVC}    ${CARD_EXPIRY_MONTH}    ${CARD_EXPIRY_YEAR}
    Click Pay And Confirm
    Verify Order Placed Successfully
    Delete Account
    Verify Account Deleted
