*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/product_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC19 View Cart Brand Products
    [Tags]    skip
    Navigate To Products Page
    Go To    ${BASE_URL}/brand_products/Polo
    Wait Until Element Is Visible    css=h2.title    timeout=10s
    Verify Brand Page Title Contains    Polo
    Verify Products Are Visible
    Go To    ${BASE_URL}/brand_products/H&M
    Wait Until Element Is Visible    css=h2.title    timeout=10s
    Verify Brand Page Title Contains    H&M
    Verify Products Are Visible
