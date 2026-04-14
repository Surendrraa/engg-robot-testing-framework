*** Settings ***
Documentation    Subscription locators collected from https://www.automationexercise.com/ (footer) and /view_cart page

*** Variables ***
# Subscription (Home Page Footer and Cart Page Footer)
${SUBSCRIPTION_HEADING}                        css=.single-widget h2
${SUBSCRIPTION_EMAIL_INPUT}                    id=susbscribe_email
${SUBSCRIBE_BUTTON}                            id=subscribe
${SUBSCRIPTION_SUCCESS_MESSAGE}                css=#success-subscribe .alert-success
