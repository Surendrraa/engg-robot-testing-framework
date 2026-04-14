*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/auth_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC03 Login User With Incorrect Email And Password
    Navigate To Login Page
    Verify Login Page Visible
    Login With Credentials    ${INVALID_EMAIL}    ${INVALID_PASS}
    Verify Login Error Message
