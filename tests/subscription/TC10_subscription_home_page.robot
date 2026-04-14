*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/subscription_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC10 Verify Subscription In Home Page
    [Tags]    skip
    Scroll To Subscription Section
    Verify Subscription Heading Visible
    ${unique_email}=    Generate Unique Email With Prefix    tc10_sub
    Enter Subscription Email    ${unique_email}
    Click Subscribe Button
    Verify Subscription Success
