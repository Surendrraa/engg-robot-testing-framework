*** Settings ***
Library           SeleniumLibrary
Variables         ../config/config.py
Variables         ../config/test_data.py
Resource          locators/subscription_locators.resource
Resource          common.resource

*** Keywords ***
Scroll To Subscription Section
    Execute Javascript    window.scrollTo(0, document.body.scrollHeight)
    Wait Until Element Is Visible    ${SUBSCRIPTION_HEADING}    timeout=${TIMEOUT}

Verify Subscription Heading Visible
    Wait Until Element Is Visible    ${SUBSCRIPTION_HEADING}    timeout=10s
    ${text}=    Get Text    ${SUBSCRIPTION_HEADING}
    Should Contain    ${text}    SUBSCRIPTION    ignore_case=True

Enter Subscription Email
    [Arguments]    ${email}
    Input Text    ${SUBSCRIPTION_EMAIL_INPUT}    ${email}

Click Subscribe Button
    Click Element    ${SUBSCRIBE_BUTTON}

Verify Subscription Success
    Wait Until Element Is Visible    ${SUBSCRIPTION_SUCCESS_MESSAGE}    timeout=${TIMEOUT}
    Element Should Be Visible    ${SUBSCRIPTION_SUCCESS_MESSAGE}
