*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/product_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC18 View Category Products
    [Tags]    skip
    Click Element    ${NAV_PRODUCTS_LINK}
    Click Category    Women
    Click Sub Category    /category_products/1
    Verify Category Page Title Contains    Women - Dress Products
    Click Category    Men
    Click Sub Category    /category_products/3
    Verify Category Page Title Contains    Men - Tshirts Products
