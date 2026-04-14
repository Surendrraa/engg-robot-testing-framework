*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC04 Logout User
    ${unique_email}=    Generate Unique Email With Prefix    tc04_logout
    # Register a new account
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    Verify Logged In As    ${SIGNUP_NAME}
    # Now test logout
    Logout From Application
    # Login again to delete account for cleanup
    Login With Credentials    ${unique_email}    ${VALID_PASS}
    Delete Account
    Verify Account Deleted
