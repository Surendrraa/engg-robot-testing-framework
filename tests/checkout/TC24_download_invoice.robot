*** Settings ***
Documentation     TC24 - Download Invoice After Purchase Order
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
TC24 Download Invoice After Purchase Order
    [Tags]    skip
    # Register with unique email
    ${unique_email}=    Generate Unique Email With Prefix    tc24_checkout
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Add product, checkout, pay
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    Navigate To Cart Page
    Click Proceed To Checkout
    Verify Checkout Page Visible
    Enter Order Comment    Invoice test order
    Click Place Order
    Fill Payment Details    ${CARD_NAME}    ${CARD_NUMBER}    ${CARD_CVC}    ${CARD_EXPIRY_MONTH}    ${CARD_EXPIRY_YEAR}
    Click Pay And Confirm
    Verify Order Placed Successfully
    Click Download Invoice
    # Verify invoice downloaded (file check can be added)
    Click Continue After Order
    Delete Account
    Verify Account Deleted
