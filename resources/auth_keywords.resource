*** Settings ***
Library           SeleniumLibrary
Variables         ../config/config.py
Variables         ../config/test_data.py
Resource          locators/auth_locators.resource
Resource          common.resource

*** Keywords ***
Navigate To Login Page
    Click Element    ${NAV_SIGNUP_LOGIN_LINK}
    Wait Until Page Contains Element    ${LOGIN_HEADING}    timeout=10s

Verify Login Page Visible
    Wait Until Page Contains Element    ${LOGIN_HEADING}    timeout=10s
    ${text}=    Get Text    ${LOGIN_HEADING}
    Should Contain    ${text}    Login to your account    ignore_case=True

Login With Credentials
    [Arguments]    ${email}    ${password}
    Input Text    ${LOGIN_EMAIL_INPUT}    ${email}
    Input Text    ${LOGIN_PASSWORD_INPUT}    ${password}
    Click Button    ${LOGIN_BUTTON}
    Sleep    2s

Verify Logged In As
    [Arguments]    ${username}
    Wait Until Page Contains Element    ${NAV_LOGGED_IN_AS_TEXT}    timeout=15s
    Element Text Should Be    ${NAV_LOGGED_IN_AS_TEXT}    ${username}

Verify Login Error Message
    Page Should Contain Element    ${LOGIN_ERROR_MESSAGE}

Logout From Application
    Click Element    ${NAV_LOGOUT_LINK}
    Wait Until Page Contains Element    ${LOGIN_HEADING}    timeout=10s

Enter Signup Name And Email
    [Arguments]    ${name}    ${email}
    Input Text    ${SIGNUP_NAME_INPUT}    ${name}
    Input Text    ${SIGNUP_EMAIL_INPUT}    ${email}
    Click Button    ${SIGNUP_BUTTON}
    Sleep    3s

Verify New User Signup Visible
    Wait Until Page Contains Element    ${SIGNUP_HEADING}    timeout=10s
    ${text}=    Get Text    ${SIGNUP_HEADING}
    Should Contain    ${text}    New User Signup    ignore_case=True

Verify Signup Error Message
    Page Should Contain Element    ${SIGNUP_ERROR_MESSAGE}

Verify Enter Account Information Visible
    Wait Until Page Contains    Enter Account Information    timeout=10s

Fill Account Information
    [Arguments]    ${password}    ${day}    ${month}    ${year}
    Click Element    ${REG_TITLE_MR_RADIO}
    Input Text    ${REG_PASSWORD_INPUT}    ${password}
    Select From List By Value    ${REG_DAYS_DROPDOWN}    ${day}
    Select From List By Label    ${REG_MONTHS_DROPDOWN}    ${month}
    Select From List By Value    ${REG_YEARS_DROPDOWN}    ${year}
    Select Checkbox    ${REG_NEWSLETTER_CHECKBOX}
    Select Checkbox    ${REG_SPECIAL_OFFERS_CHECKBOX}

Fill Address Information
    [Arguments]    ${first}    ${last}    ${company}    ${address}    ${address2}    ${country}    ${state}    ${city}    ${zip}    ${mobile}
    Input Text    ${REG_FIRST_NAME_INPUT}    ${first}
    Input Text    ${REG_LAST_NAME_INPUT}    ${last}
    Input Text    ${REG_COMPANY_INPUT}    ${company}
    Input Text    ${REG_ADDRESS_INPUT}    ${address}
    Input Text    ${REG_ADDRESS2_INPUT}    ${address2}
    Select From List By Label    ${REG_COUNTRY_DROPDOWN}    ${country}
    Input Text    ${REG_STATE_INPUT}    ${state}
    Input Text    ${REG_CITY_INPUT}    ${city}
    Input Text    ${REG_ZIPCODE_INPUT}    ${zip}
    Input Text    ${REG_MOBILE_NUMBER_INPUT}    ${mobile}

Click Create Account
    Click Button    ${REG_CREATE_ACCOUNT_BUTTON}
    Sleep    3s

Verify Account Created
    Wait Until Page Contains    Account Created    timeout=20s

Click Continue After Account Created
    Click Element    ${ACCOUNT_CREATED_CONTINUE_BUTTON}
    Sleep    3s
    Wait Until Page Contains Element    ${NAV_HOME_LINK}    timeout=15s

Delete Account
    Click Element    ${NAV_DELETE_ACCOUNT_LINK}
    Sleep    3s
    Wait Until Page Contains    Account Deleted    timeout=15s

Verify Account Deleted
    Wait Until Page Contains    Account Deleted    timeout=15s

Register And Login With Unique Email
    [Documentation]    Register a new account with a unique email, complete registration, verify logged in
    [Arguments]    ${name}=${SIGNUP_NAME}    ${password}=${VALID_PASS}
    ${unique_email}=    Generate Unique Email
    Set Test Variable    ${CURRENT_TEST_EMAIL}    ${unique_email}
    Navigate To Login Page
    Enter Signup Name And Email    ${name}    ${unique_email}
    Verify Enter Account Information Visible
    Fill Account Information    ${password}    15    March    1995
    Fill Address Information    ${FIRST_NAME}    ${LAST_NAME}    ${COMPANY}    ${ADDRESS1}    ${ADDRESS2}    ${COUNTRY}    ${STATE}    ${CITY}    ${ZIPCODE}    ${MOBILE}
    Click Create Account
    Verify Account Created
    Click Continue After Account Created
    Verify Logged In As    ${name}

