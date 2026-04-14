*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC02 Login User With Correct Email And Password
    ${unique_email}=    Generate Unique Email With Prefix    tc02_login
    # First register a new account
    Navigate To Login Page
    Enter Signup Name And Email    ${SIGNUP_NAME}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${VALID_PASS}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    # Logout and re-login to verify
    Logout From Application
    Login With Credentials    ${unique_email}    ${VALID_PASS}
    Verify Logged In As    ${SIGNUP_NAME}
    Delete Account
    Verify Account Deleted
