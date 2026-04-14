*** Settings ***
Documentation    Payment Page locators collected from https://www.automationexercise.com/payment

*** Variables ***
# Payment Breadcrumb and Heading
${PAYMENT_BREADCRUMB}                          xpath=//ol[@class='breadcrumb']//li[contains(text(),'Payment')]
${PAYMENT_HEADING}                             xpath=//h2[contains(text(),'Payment')]

# Payment Form
${PAYMENT_FORM}                                id=payment-form
${NAME_ON_CARD_INPUT}                          css=input[data-qa='name-on-card']
${CARD_NUMBER_INPUT}                           css=input[data-qa='card-number']
${CVC_INPUT}                                   css=input[data-qa='cvc']
${EXPIRY_MONTH_INPUT}                          css=input[data-qa='expiry-month']
${EXPIRY_YEAR_INPUT}                           css=input[data-qa='expiry-year']
${PAY_BUTTON}                                  css=button[data-qa='pay-button']
${PAYMENT_SUCCESS_MESSAGE}                     css=#success_message .alert-success

# Order Placed Page (after payment)
${ORDER_CONFIRMED_HEADING}                     css=h2[data-qa='order-placed']
${ORDER_CONFIRMED_HEADING_ALT}                 xpath=//b[text()='Order Placed!']
${CONTINUE_BUTTON}                             css=a[data-qa='continue-button']
${DOWNLOAD_INVOICE_LINK}                       css=a.btn.btn-default.check_out
