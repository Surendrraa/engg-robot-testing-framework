*** Settings ***
Library           SeleniumLibrary
Variables         ../config/config.py
Variables         ../config/test_data.py
Resource          locators/checkout_locators.resource
Resource          locators/payment_locators.resource
Resource          common.resource

*** Keywords ***
Verify Checkout Page Visible
    Wait Until Page Contains Element    ${ADDRESS_DETAILS_HEADING}    timeout=10s

Verify Delivery Address Name
    [Arguments]    ${expected_name}
    Element Should Contain    ${DELIVERY_ADDRESS_NAME}    ${expected_name}

Verify Delivery Address Phone
    [Arguments]    ${expected_phone}
    Element Should Contain    ${DELIVERY_ADDRESS_PHONE}    ${expected_phone}

Verify Billing Address Name
    [Arguments]    ${expected_name}
    Element Should Contain    ${BILLING_ADDRESS_NAME}    ${expected_name}

Verify Review Order Visible
    Page Should Contain Element    ${REVIEW_ORDER_HEADING}

Enter Order Comment
    [Arguments]    ${comment}
    Input Text    ${CHECKOUT_COMMENT_TEXTAREA}    ${comment}

Click Place Order
    Click Element    ${PLACE_ORDER_LINK}
    Wait Until Page Contains Element    ${NAME_ON_CARD_INPUT}    timeout=15s

Fill Payment Details
    [Arguments]    ${name}    ${card}    ${cvc}    ${month}    ${year}
    Input Text    ${NAME_ON_CARD_INPUT}    ${name}
    Input Text    ${CARD_NUMBER_INPUT}    ${card}
    Input Text    ${CVC_INPUT}    ${cvc}
    Input Text    ${EXPIRY_MONTH_INPUT}    ${month}
    Input Text    ${EXPIRY_YEAR_INPUT}    ${year}

Click Pay And Confirm
    Click Button    ${PAY_BUTTON}
    Sleep    3s

Verify Order Placed Successfully
    Wait Until Page Contains    Order Placed    timeout=15s

Click Continue After Order
    Click Element    ${CONTINUE_BUTTON}

Click Download Invoice
    Click Element    ${DOWNLOAD_INVOICE_LINK}

Verify Delivery Address Details
    [Arguments]    ${name}    ${company}    ${address1}    ${address2}    ${city_state_zip}    ${country}    ${phone}
    Element Should Contain    ${DELIVERY_ADDRESS_NAME}    ${name}
    Element Should Contain    ${DELIVERY_ADDRESS_COMPANY}    ${company}
    Element Should Contain    ${DELIVERY_ADDRESS_LINE1}    ${address1}
    Element Should Contain    ${DELIVERY_ADDRESS_LINE2}    ${address2}
    Element Should Contain    ${DELIVERY_ADDRESS_CITY_STATE_ZIP}    ${city_state_zip}
    Element Should Contain    ${DELIVERY_ADDRESS_COUNTRY}    ${country}
    Element Should Contain    ${DELIVERY_ADDRESS_PHONE}    ${phone}

Verify Billing Address Details
    [Arguments]    ${name}    ${company}    ${address1}    ${address2}    ${city_state_zip}    ${country}    ${phone}
    Element Should Contain    ${BILLING_ADDRESS_NAME}    ${name}
    Element Should Contain    ${BILLING_ADDRESS_COMPANY}    ${company}
    Element Should Contain    ${BILLING_ADDRESS_LINE1}    ${address1}
    Element Should Contain    ${BILLING_ADDRESS_LINE2}    ${address2}
    Element Should Contain    ${BILLING_ADDRESS_CITY_STATE_ZIP}    ${city_state_zip}
    Element Should Contain    ${BILLING_ADDRESS_COUNTRY}    ${country}
    Element Should Contain    ${BILLING_ADDRESS_PHONE}    ${phone}
