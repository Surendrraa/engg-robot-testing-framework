*** Settings ***
Library           SeleniumLibrary
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/common.resource
Resource          ../../resources/locators/contact_locators.resource
Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser

*** Test Cases ***
TC06 Contact Us Form
    [Tags]    skip
    Click Element    ${NAV_CONTACT_US_LINK}
    Page Should Contain    Get In Touch
    ${unique_email}=    Generate Unique Email With Prefix    tc06_contact
    Input Text    ${CONTACT_NAME_INPUT}    ${CONTACT_NAME}
    Input Text    ${CONTACT_EMAIL_INPUT}    ${unique_email}
    Input Text    ${CONTACT_SUBJECT_INPUT}    ${CONTACT_SUBJECT}
    Input Text    ${CONTACT_MESSAGE_TEXTAREA}    ${CONTACT_MESSAGE}
    # Upload file step - optional, can use Choose File keyword
    Click Element    ${CONTACT_SUBMIT_BUTTON}
    # Handle alert
    Handle Alert    action=ACCEPT
    Page Should Contain    Success! Your details have been submitted successfully.
    Click Element    ${NAV_HOME_LINK}
    Title Should Be    Automation Exercise
