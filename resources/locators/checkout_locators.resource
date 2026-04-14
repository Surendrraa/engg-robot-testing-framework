*** Settings ***
Documentation    Checkout Page locators collected from https://www.automationexercise.com/checkout

*** Variables ***
# Breadcrumb
${CHECKOUT_BREADCRUMB}                         xpath=//ol[@class='breadcrumb']//li[contains(text(),'Checkout')]

# Address Details
${ADDRESS_DETAILS_HEADING}                     xpath=//h2[contains(text(),'Address Details')]

# Delivery Address
${DELIVERY_ADDRESS_CONTAINER}                  id=address_delivery
${DELIVERY_ADDRESS_TITLE}                      css=#address_delivery .address_title h3
${DELIVERY_ADDRESS_NAME}                       css=#address_delivery .address_firstname.address_lastname
${DELIVERY_ADDRESS_COMPANY}                    xpath=(//ul[@id='address_delivery']/li[@class='address_address1 address_address2'])[1]
${DELIVERY_ADDRESS_LINE1}                      xpath=(//ul[@id='address_delivery']/li[@class='address_address1 address_address2'])[2]
${DELIVERY_ADDRESS_LINE2}                      xpath=(//ul[@id='address_delivery']/li[@class='address_address1 address_address2'])[3]
${DELIVERY_ADDRESS_CITY_STATE_ZIP}             css=#address_delivery .address_city.address_state_name.address_postcode
${DELIVERY_ADDRESS_COUNTRY}                    css=#address_delivery .address_country_name
${DELIVERY_ADDRESS_PHONE}                      css=#address_delivery .address_phone

# Billing Address
${BILLING_ADDRESS_CONTAINER}                   id=address_invoice
${BILLING_ADDRESS_TITLE}                       css=#address_invoice .address_title h3
${BILLING_ADDRESS_NAME}                        css=#address_invoice .address_firstname.address_lastname
${BILLING_ADDRESS_COMPANY}                     xpath=(//ul[@id='address_invoice']/li[@class='address_address1 address_address2'])[1]
${BILLING_ADDRESS_LINE1}                       xpath=(//ul[@id='address_invoice']/li[@class='address_address1 address_address2'])[2]
${BILLING_ADDRESS_LINE2}                       xpath=(//ul[@id='address_invoice']/li[@class='address_address1 address_address2'])[3]
${BILLING_ADDRESS_CITY_STATE_ZIP}              css=#address_invoice .address_city.address_state_name.address_postcode
${BILLING_ADDRESS_COUNTRY}                     css=#address_invoice .address_country_name
${BILLING_ADDRESS_PHONE}                       css=#address_invoice .address_phone

# Order Review
${REVIEW_ORDER_HEADING}                        xpath=//h2[contains(text(),'Review Your Order')]
${ORDER_TABLE}                                 css=#cart_info_table
${ORDER_TABLE_ALT}                             css=table.table-condensed
${ORDER_ITEM_ROWS}                             css=#cart_info_table tbody tr
${ORDER_PRODUCT_NAME}                          css=td.cart_description h4 a
${ORDER_PRICE}                                 css=td.cart_price p
${ORDER_QUANTITY}                              css=td.cart_quantity button
${ORDER_ITEM_TOTAL}                            css=td.cart_total .cart_total_price
${ORDER_GRAND_TOTAL}                           css=.cart_total_price

# Comment Area
${CHECKOUT_COMMENT_TEXTAREA}                   css=textarea.form-control
${PLACE_ORDER_LINK}                            css=a[href='/payment']
