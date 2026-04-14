*** Settings ***
Library           SeleniumLibrary
Resource          ../../resources/product_keywords.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC09 Search Product
    [Tags]    skip
    Navigate To Products Page
    Verify All Products Page Visible
    Search For Product    ${SEARCH_TERM}
    Verify Search Results Visible
    Verify Products Are Visible
