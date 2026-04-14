*** Settings ***
Documentation     TC22 - Add To Cart From Recommended Items
Resource          ../../resources/common.resource
Variables         ../../config/config.py
Variables         ../../config/test_data.py
Resource          ../../resources/cart_keywords.resource

Test Setup        Open Browser To Home Page
Test Teardown     Run Keywords    Cleanup Test User    AND    Close Test Browser


*** Test Cases ***
TC22 Add To Cart From Recommended Items
    Execute Javascript    window.scrollTo(0, document.body.scrollHeight)
    Sleep    2s
    Wait Until Element Is Visible    ${RECOMMENDED_SECTION_HEADING}    timeout=10s
    Scroll Element Into View    ${RECOMMENDED_SECTION_HEADING}
    Sleep    1s
    ${add_buttons}=    Get WebElements    ${RECOMMENDED_PRODUCT_ADD_TO_CART}
    Execute Javascript    arguments[0].click()    ARGUMENTS    ${add_buttons}[0]
    Wait Until Element Is Visible    ${CART_MODAL_VIEW_CART_LINK}    timeout=10s
    Click View Cart In Modal
    Verify Cart Page Visible
    Verify Cart Has N Products    1
