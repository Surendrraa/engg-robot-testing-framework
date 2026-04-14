*** Settings ***
Library           SeleniumLibrary
Variables         ../config/config.py
Variables         ../config/test_data.py
Resource          locators/products_locators.resource
Resource          common.resource

*** Keywords ***
Navigate To Products Page
    Click Element    ${NAV_PRODUCTS_LINK}
    Wait Until Page Contains Element    ${ALL_PRODUCTS_TITLE}    timeout=10s

Verify All Products Page Visible
    Page Should Contain Element    ${ALL_PRODUCTS_TITLE}
    Element Should Contain    ${ALL_PRODUCTS_TITLE}    ALL PRODUCTS

Search For Product
    [Arguments]    ${product_name}
    Input Text    ${SEARCH_INPUT}    ${product_name}
    Click Element    ${SEARCH_BUTTON}

Verify Search Results Visible
    Element Should Contain    ${SEARCHED_PRODUCTS_TITLE}    SEARCHED PRODUCTS

Verify Products Are Visible
    Page Should Contain Element    ${PRODUCT_INFO_OVERLAY}

Click View Product
    [Arguments]    ${index}=1
    Click Element    xpath=(//a[contains(@href, 'product_details')])[${index}]

Click First View Product
    Scroll Element Into View    ${FIRST_VIEW_PRODUCT}
    Click Element    ${FIRST_VIEW_PRODUCT}
    Wait Until Page Contains Element    ${PRODUCT_NAME}    timeout=10s

Verify Product Detail Page Visible
    Wait Until Page Contains Element    ${PRODUCT_NAME}    timeout=10s

Get Product Detail Name
    ${name}=    Get Text    ${PRODUCT_NAME}
    RETURN    ${name}

Get Product Detail Category
    ${cat}=    Get Text    ${PRODUCT_CATEGORY}
    RETURN    ${cat}

Get Product Detail Price
    ${price}=    Get Text    ${PRODUCT_PRICE}
    RETURN    ${price}

Get Product Detail Availability
    Wait Until Page Contains    Availability    timeout=10s
    ${avail}=    Get Text    xpath=//b[contains(text(),'Availability')]/parent::p
    RETURN    ${avail}

Get Product Detail Condition
    ${cond}=    Get Text    xpath=//b[contains(text(),'Condition')]/parent::p
    RETURN    ${cond}

Get Product Detail Brand
    ${brand}=    Get Text    xpath=//b[contains(text(),'Brand')]/parent::p
    RETURN    ${brand}

Set Product Quantity
    [Arguments]    ${qty}
    Wait Until Element Is Visible    ${QUANTITY_INPUT}    timeout=10s
    Clear Element Text    ${QUANTITY_INPUT}
    Input Text    ${QUANTITY_INPUT}    ${qty}

Click Add To Cart On Detail Page
    Wait Until Element Is Visible    ${ADD_TO_CART_BUTTON}    timeout=10s
    Click Button    ${ADD_TO_CART_BUTTON}
    Wait Until Element Is Visible    ${CART_MODAL_CONTINUE_SHOPPING_BTN}    timeout=10s

Click Category
    [Arguments]    ${category}
    Click Element    xpath=//a[@href='#${category}']
    Sleep    1s

Click Sub Category
    [Arguments]    ${sub_category_url}
    Click Element    css=a[href='${sub_category_url}']
    Sleep    2s

Verify Category Page Title Contains
    [Arguments]    ${text}
    Wait Until Element Is Visible    ${CATEGORY_PAGE_TITLE}    timeout=10s
    ${actual}=    Get Text    ${CATEGORY_PAGE_TITLE}
    ${actual_normalized}=    Evaluate    ' '.join($actual.upper().split())
    ${expected_normalized}=    Evaluate    ' '.join($text.upper().split())
    Should Contain    ${actual_normalized}    ${expected_normalized}

Click Brand
    [Arguments]    ${brand_url}
    Click Element    css=a[href='${brand_url}']
    Sleep    2s

Verify Brand Page Title Contains
    [Arguments]    ${text}
    Wait Until Element Is Visible    ${BRAND_PAGE_TITLE}    timeout=10s
    ${actual}=    Get Text    ${BRAND_PAGE_TITLE}
    Should Contain    ${actual}    ${text}    ignore_case=True

Hover Over Product And Add To Cart
    [Arguments]    ${index}
    Wait Until Element Is Visible    xpath=(//div[@class='productinfo text-center'])[${index}]    timeout=10s
    Scroll Element Into View    xpath=(//div[@class='product-image-wrapper'])[${index}]
    Sleep    1s
    ${add_btn}=    Get WebElement    xpath=(//div[@class='productinfo text-center'])[${index}]//a[contains(@class,'add-to-cart')]
    Execute Javascript    arguments[0].click()    ARGUMENTS    ${add_btn}
    Wait Until Element Is Visible    ${CART_MODAL_CONTINUE_SHOPPING_BTN}    timeout=10s

Write Product Review
    [Arguments]    ${name}    ${email}    ${review}
    Input Text    ${REVIEW_NAME_INPUT}    ${name}
    Input Text    ${REVIEW_EMAIL_INPUT}    ${email}
    Input Text    ${REVIEW_TEXTAREA}    ${review}
    Click Button    ${REVIEW_SUBMIT_BUTTON}

Verify Review Success Message
    Page Should Contain Element    ${REVIEW_SUCCESS_MESSAGE}
