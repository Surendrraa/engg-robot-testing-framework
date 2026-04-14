*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/subscription_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC11 Verify Subscription In Cart Page
    [Tags]    skip
    Click Element    ${NAV_CART_LINK}
    Scroll To Subscription Section
    Verify Subscription Heading Visible
    ${unique_email}=    Generate Unique Email With Prefix    tc11_sub
    Enter Subscription Email    ${unique_email}
    Click Subscribe Button
    Verify Subscription Success
