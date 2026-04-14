*** Settings ***
Library           SeleniumLibrary
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Resource          ../../resources/locators/navigation_locators.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC07 Verify Test Cases Page
    [Tags]    skip
    Click Element    ${NAV_TEST_CASES_LINK}
    Page Should Contain    Test Cases
    Page Should Contain Element    css=.panel-group
