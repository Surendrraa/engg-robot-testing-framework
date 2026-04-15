*** Settings ***
Library           SeleniumLibrary
Library           Collections
Variables         ../config/config.py
Variables         ../config/test_data.py
Resource          locators/cart_locators.resource
Resource          locators/auth_locators.resource
Resource          common.resource

*** Keywords ***
Navigate To Cart Page
    Click Element    ${NAV_CART_LINK}
    Wait Until Page Contains Element    ${CART_INFO_TABLE}    timeout=10s

Verify Cart Page Visible
    Page Should Contain Element    ${CART_INFO_TABLE}

Verify Product In Cart
    [Arguments]    ${product_name}
    Page Should Contain    ${product_name}

Verify Cart Has N Products
    [Arguments]    ${count}
    ${rows}=    Get Element Count    ${CART_ITEM_ROWS}
    Should Be Equal As Integers    ${rows}    ${count}

Get Cart Product Names
    ${elements}=    Get WebElements    ${CART_PRODUCT_NAME}
    ${names}=    Create List
    FOR    ${el}    IN    @{elements}
        ${name}=    Get Text    ${el}
        Append To List    ${names}    ${name}
    END
    RETURN    ${names}

Get Cart Product Prices
    ${elements}=    Get WebElements    ${CART_PRICE}
    ${prices}=    Create List
    FOR    ${el}    IN    @{elements}
        ${price}=    Get Text    ${el}
        Append To List    ${prices}    ${price}
    END
    RETURN    ${prices}

Get Cart Quantity
    [Arguments]    ${product_index}=1
    ${qty}=    Get Text    css=#cart_info_table tbody tr:nth-child(${product_index}) td.cart_quantity button
    RETURN    ${qty}

Remove Product From Cart
    [Arguments]    ${index}=1
    Click Element    xpath=(//a[@class='cart_quantity_delete'])[${index}]
    Sleep    2s

Click Proceed To Checkout
    Click Element    ${PROCEED_TO_CHECKOUT_BUTTON}

Verify Empty Cart
    Wait Until Page Contains Element    ${EMPTY_CART_TEXT}    timeout=10s

Click Continue Shopping In Modal
    Wait Until Element Is Visible    ${CART_MODAL_CONTINUE_SHOPPING_BTN}    timeout=15s
    ${clicked}=    Run Keyword And Return Status    Click Element    ${CART_MODAL_CONTINUE_SHOPPING_BTN}
    IF    not ${clicked}
        Execute JavaScript    document.querySelector('#cartModal .close-modal').click()
    END
    Sleep    1s

Click View Cart In Modal
    Wait Until Element Is Visible    ${CART_MODAL_VIEW_CART_LINK}    timeout=10s
    Click Element    ${CART_MODAL_VIEW_CART_LINK}
    Wait Until Page Contains Element    ${CART_INFO_TABLE}    timeout=10s

Click Register Login In Checkout Modal
    Wait Until Element Is Visible    ${CHECKOUT_MODAL_LOGIN_LINK}    timeout=10s
    Click Element    ${CHECKOUT_MODAL_LOGIN_LINK}
    Wait Until Page Contains Element    ${LOGIN_HEADING}    timeout=10s
