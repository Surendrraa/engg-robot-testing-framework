*** Settings ***
Documentation    Locators for Products page (/products) and Product Detail page (/product_details/{id})
...              Collected from https://www.automationexercise.com/ using Playwright CLI.


*** Variables ***

# =============================================================================
# ALL PRODUCTS PAGE (/products)
# =============================================================================

# --- All Products Section ---
${ALL_PRODUCTS_TITLE}                       css=h2.title
${SEARCH_INPUT}                             id=search_product
${SEARCH_BUTTON}                            id=submit_search
${SEARCHED_PRODUCTS_TITLE}                  css=h2.title
${PRODUCT_LIST_CONTAINER}                   css=.features_items
${SINGLE_PRODUCT_CARD}                      css=.product-image-wrapper
${PRODUCT_INFO_OVERLAY}                     css=.productinfo
${PRODUCT_NAME_IN_CARD}                     css=.productinfo p
${PRODUCT_PRICE_IN_CARD}                    css=.productinfo h2
${ADD_TO_CART_OVERLAY}                      css=.productinfo .add-to-cart
${ADD_TO_CART_CARD}                         css=.product-overlay .add-to-cart
${VIEW_PRODUCT_LINK}                        css=a[href*='product_details']
${FIRST_VIEW_PRODUCT}                       xpath=(//a[contains(@href, 'product_details')])[1]

# --- Categories Sidebar ---
${CATEGORY_PANEL}                           id=accordian
${WOMEN_CATEGORY_LINK}                      xpath=//a[@href='#Women']
${MEN_CATEGORY_LINK}                        xpath=//a[@href='#Men']
${KIDS_CATEGORY_LINK}                       xpath=//a[@href='#Kids']
${WOMEN_DRESS_LINK}                         css=a[href='/category_products/1']
${WOMEN_TOPS_LINK}                          css=a[href='/category_products/2']
${WOMEN_SAREE_LINK}                         css=a[href='/category_products/7']
${MEN_TSHIRTS_LINK}                         css=a[href='/category_products/3']
${MEN_JEANS_LINK}                           css=a[href='/category_products/6']
${KIDS_DRESS_LINK}                          css=a[href='/category_products/4']
${KIDS_TOPS_SHIRTS_LINK}                    css=a[href='/category_products/5']
${CATEGORY_PAGE_TITLE}                      css=h2.title

# --- Brands Sidebar ---
${BRANDS_HEADING}                           css=.brands_products h2
${BRAND_POLO}                               css=a[href='/brand_products/Polo']
${BRAND_HM}                                 css=a[href='/brand_products/H&M']
${BRAND_MADAME}                             css=a[href='/brand_products/Madame']
${BRAND_MAST_HARBOUR}                       css=a[href*='Mast']
${BRAND_BABYHUG}                            css=a[href='/brand_products/Babyhug']
${BRAND_ALLEN_SOLLY_JUNIOR}                 css=a[href*='Allen Solly']
${BRAND_KOOKIE_KIDS}                        css=a[href*='Kookie Kids']
${BRAND_BIBA}                               css=a[href='/brand_products/Biba']
${BRAND_PAGE_TITLE}                         css=h2.title

# =============================================================================
# PRODUCT DETAIL PAGE (/product_details/{id})
# =============================================================================

# --- Product Information ---
${PRODUCT_NAME}                             css=.product-information h2
${PRODUCT_CATEGORY}                         css=.product-information p:first-of-type
${PRODUCT_PRICE}                            css=.product-information span span
${QUANTITY_INPUT}                           id=quantity
${ADD_TO_CART_BUTTON}                       css=button.btn.btn-default.cart
${PRODUCT_AVAILABILITY}                     xpath=//b[contains(text(),'Availability')]/parent::p
${PRODUCT_CONDITION}                        xpath=//b[contains(text(),'Condition')]/parent::p
${PRODUCT_BRAND}                            xpath=//b[contains(text(),'Brand')]/parent::p

# --- Product Review Section ---
${WRITE_YOUR_REVIEW_TAB}                    css=a[href='#reviews']
${REVIEW_NAME_INPUT}                        css=#review-form input[placeholder='Your Name']
${REVIEW_EMAIL_INPUT}                       css=#review-form input[placeholder='Email Address']
${REVIEW_TEXTAREA}                          css=#review-form textarea
${REVIEW_SUBMIT_BUTTON}                     css=#review-form button[type='submit']
${REVIEW_SUCCESS_MESSAGE}                   css=.alert-success
