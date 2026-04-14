*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/product_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC21 Add Review On Product
    [Tags]    skip
    Go To    ${BASE_URL}/product_details/1
    Verify Product Detail Page Visible
    ${unique_email}=    Generate Unique Email With Prefix    tc21_review
    Write Product Review    ${SIGNUP_NAME}    ${unique_email}    Great product quality!
    Verify Review Success Message
