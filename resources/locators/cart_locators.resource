*** Settings ***
Documentation    Locators for Cart page (/view_cart)
...              Collected from https://www.automationexercise.com/ using Playwright CLI.


*** Variables ***

# =============================================================================
# CART PAGE (/view_cart)
# =============================================================================

# --- Breadcrumb ---
${HOME_BREADCRUMB}                          xpath=//ol[@class='breadcrumb']//a[text()='Home']
${SHOPPING_CART_BREADCRUMB}                 xpath=//ol[@class='breadcrumb']//li[contains(text(),'Shopping Cart')]

# --- Cart Table ---
${CART_INFO_TABLE}                          id=cart_info_table
${CART_HEADER_ROW}                          css=tr.cart_menu
${CART_ITEM_ROWS}                           css=#cart_info_table tbody tr
${CART_PRODUCT_IMAGE}                       css=td.cart_product img
${CART_PRODUCT_NAME}                        css=td.cart_description h4 a
${CART_PRODUCT_CATEGORY}                    css=td.cart_description p
${CART_PRICE}                               css=td.cart_price p
${CART_QUANTITY}                            css=td.cart_quantity button
${CART_TOTAL}                               css=td.cart_total .cart_total_price
${CART_DELETE_BUTTON}                       css=a.cart_quantity_delete
${EMPTY_CART_TEXT}                          css=#empty_cart

# --- Proceed to Checkout ---
${PROCEED_TO_CHECKOUT_BUTTON}              css=a.check_out

# --- Register/Login Modal (shown when not logged in) ---
${CHECKOUT_MODAL_LOGIN_LINK}               css=#checkoutModal a[href='/login']
${CHECKOUT_MODAL_TEXT}                     css=#checkoutModal .modal-body p
