*** Settings ***
Documentation     TC20 - Search Products And Verify Cart After Login
Library           SeleniumLibrary
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/product_keywords.resource
Resource          ../../resources/cart_keywords.resource
Resource          ../../resources/auth_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC20 Search Products And Verify Cart After Login
    # Register a fresh account first
    ${unique_email}=    Generate Unique Email With Prefix    tc20_cart
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Search and add to cart while logged in
    Navigate To Products Page
    Search For Product    ${SEARCH_TERM}
    Verify Search Results Visible
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    # Go to cart and verify
    Go To    ${BASE_URL}/view_cart
    Wait Until Page Contains    ${SEARCH_TERM}    timeout=10s
    # Logout and login back
    Logout From Application
    Login With Credentials    ${unique_email}    ${VALID_PASS}
    Verify Logged In As    ${SIGNUP_NAME}
    # Verify cart still has the product after re-login
    Go To    ${BASE_URL}/view_cart
    Wait Until Page Contains    ${SEARCH_TERM}    timeout=10s
    # Cleanup
    Delete Account
    Verify Account Deleted
