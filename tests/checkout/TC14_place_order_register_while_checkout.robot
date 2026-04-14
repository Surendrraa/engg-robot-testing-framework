*** Settings ***
Documentation     TC14 - Place Order Register While Checkout
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
TC14 Place Order Register While Checkout
    [Tags]    skip
    # Add products to cart
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    # Go to cart and proceed to checkout
    Navigate To Cart Page
    Verify Cart Page Visible
    Click Proceed To Checkout
    # Click register/login in modal
    Click Register Login In Checkout Modal
    # Register new user with unique email
    ${unique_email}=    Generate Unique Email With Prefix    tc14_checkout
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Go to cart again and checkout
    Navigate To Cart Page
    Click Proceed To Checkout
    Verify Checkout Page Visible
    Verify Review Order Visible
    Enter Order Comment    Please deliver between 9 AM to 5 PM
    Click Place Order
    # Payment
    Fill Payment Details    ${CARD_NAME}    ${CARD_NUMBER}    ${CARD_CVC}    ${CARD_EXPIRY_MONTH}    ${CARD_EXPIRY_YEAR}
    Click Pay And Confirm
    Verify Order Placed Successfully
    # Cleanup
    Delete Account
    Verify Account Deleted
