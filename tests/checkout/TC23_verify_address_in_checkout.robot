*** Settings ***
Documentation     TC23 - Verify Address Details In Checkout Page
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
TC23 Verify Address Details In Checkout Page
    [Tags]    skip
    # Register with known address using unique email
    ${unique_email}=    Generate Unique Email With Prefix    tc23_checkout
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Add product and go to checkout
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    Navigate To Cart Page
    Click Proceed To Checkout
    # Verify delivery and billing address
    Verify Delivery Address Details    Mr. ${FIRST_NAME} ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${CITY} ${STATE} ${ZIPCODE}    ${COUNTRY}    ${MOBILE}
    Verify Billing Address Details    Mr. ${FIRST_NAME} ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${CITY} ${STATE} ${ZIPCODE}    ${COUNTRY}    ${MOBILE}
    # Cleanup
    Delete Account
    Verify Account Deleted
