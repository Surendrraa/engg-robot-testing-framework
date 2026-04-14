*** Settings ***
Documentation     TC13 - Verify Product Quantity In Cart
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/product_keywords.resource
Resource          ../../resources/cart_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC13 Verify Product Quantity In Cart
    [Tags]    skip
    Go To    ${BASE_URL}/product_details/1
    Wait Until Page Contains Element    ${PRODUCT_NAME}    timeout=10s
    Set Product Quantity    4
    Click Add To Cart On Detail Page
    Click View Cart In Modal
    Verify Cart Page Visible
    ${qty}=    Get Cart Quantity    1
    Should Be Equal As Strings    ${qty}    4
