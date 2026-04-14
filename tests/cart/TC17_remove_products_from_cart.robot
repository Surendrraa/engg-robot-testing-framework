*** Settings ***
Documentation     TC17 - Remove Products From Cart
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/product_keywords.resource
Resource          ../../resources/cart_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC17 Remove Products From Cart
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    Navigate To Cart Page
    Verify Cart Page Visible
    Remove Product From Cart    1
    Wait Until Page Contains    Cart is empty    timeout=10s
