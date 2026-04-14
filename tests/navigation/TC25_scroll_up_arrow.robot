*** Settings ***
Library           SeleniumLibrary
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Resource          ../../resources/locators/navigation_locators.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC25 Verify Scroll Up Using Arrow Button
    [Tags]    skip
    Execute Javascript    window.scrollTo(0, document.body.scrollHeight)
    Wait Until Element Is Visible    id=scrollUp    timeout=5s
    Click Element    id=scrollUp
    Wait Until Element Is Visible    xpath=//h2[contains(text(),'Full-Fledged')]    timeout=5s
    Element Should Be Visible    xpath=//h2[contains(text(),'Full-Fledged')]
