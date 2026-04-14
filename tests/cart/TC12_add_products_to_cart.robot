*** Settings ***
Documentation     TC12 - Add Products In Cart
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/product_keywords.resource
Resource          ../../resources/cart_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC12 Add Products In Cart
    Navigate To Products Page
    Hover Over Product And Add To Cart    1
    Click Continue Shopping In Modal
    Hover Over Product And Add To Cart    2
    Click View Cart In Modal
    Verify Cart Page Visible
    Verify Cart Has N Products    2
