*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/product_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC08 Verify All Products And Product Detail Page
    [Tags]    skip
    Navigate To Products Page
    Verify All Products Page Visible
    Click First View Product
    Verify Product Detail Page Visible
    ${name}=    Get Product Detail Name
    ${category}=    Get Product Detail Category
    ${price}=    Get Product Detail Price
    ${availability}=    Get Product Detail Availability
    ${condition}=    Get Product Detail Condition
    ${brand}=    Get Product Detail Brand
    Should Not Be Empty    ${name}
    Should Not Be Empty    ${category}
    Should Not Be Empty    ${price}
    Should Not Be Empty    ${availability}
    Should Not Be Empty    ${condition}
    Should Not Be Empty    ${brand}
