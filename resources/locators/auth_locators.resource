*** Settings ***
Documentation    Auth locators for login page, signup page, registration form,
...              account created page, and account deleted page.

*** Variables ***
# ========== Login Page (url: /login) ==========
${LOGIN_HEADING}                        css=.login-form h2
${LOGIN_EMAIL_INPUT}                    css=input[data-qa='login-email']
${LOGIN_PASSWORD_INPUT}                 css=input[data-qa='login-password']
${LOGIN_BUTTON}                         css=button[data-qa='login-button']
${LOGIN_ERROR_MESSAGE}                  css=p[style='color: red;']

# ========== Signup Section (url: /login) ==========
${SIGNUP_HEADING}                       css=.signup-form h2
${SIGNUP_NAME_INPUT}                    css=input[data-qa='signup-name']
${SIGNUP_EMAIL_INPUT}                   css=input[data-qa='signup-email']
${SIGNUP_BUTTON}                        css=button[data-qa='signup-button']
${SIGNUP_ERROR_MESSAGE}                 css=p[style='color: red;']

# ========== Registration Form (url: /signup) ==========
${REG_ACCOUNT_INFO_HEADING}             css=.login-form h2
${REG_TITLE_MR_RADIO}                   id=id_gender1
${REG_TITLE_MRS_RADIO}                  id=id_gender2
${REG_NAME_INPUT}                       css=input[data-qa='name']
${REG_EMAIL_INPUT}                      css=input[data-qa='email']
${REG_PASSWORD_INPUT}                   css=input[data-qa='password']
${REG_DAYS_DROPDOWN}                    id=days
${REG_MONTHS_DROPDOWN}                  id=months
${REG_YEARS_DROPDOWN}                   id=years
${REG_NEWSLETTER_CHECKBOX}              id=newsletter
${REG_SPECIAL_OFFERS_CHECKBOX}          id=optin
${REG_FIRST_NAME_INPUT}                 css=input[data-qa='first_name']
${REG_LAST_NAME_INPUT}                  css=input[data-qa='last_name']
${REG_COMPANY_INPUT}                    css=input[data-qa='company']
${REG_ADDRESS_INPUT}                    css=input[data-qa='address']
${REG_ADDRESS2_INPUT}                   css=input[data-qa='address2']
${REG_COUNTRY_DROPDOWN}                 css=select[data-qa='country']
${REG_STATE_INPUT}                      css=input[data-qa='state']
${REG_CITY_INPUT}                       css=input[data-qa='city']
${REG_ZIPCODE_INPUT}                    css=input[data-qa='zipcode']
${REG_MOBILE_NUMBER_INPUT}              css=input[data-qa='mobile_number']
${REG_CREATE_ACCOUNT_BUTTON}            css=button[data-qa='create-account']

# ========== Account Created Page (url: /account_created) ==========
${ACCOUNT_CREATED_HEADING}              css=h2[data-qa='account-created']
${ACCOUNT_CREATED_CONTINUE_BUTTON}      css=a[data-qa='continue-button']

# ========== Account Deleted Page (url: /delete_account) ==========
${ACCOUNT_DELETED_HEADING}              css=h2[data-qa='account-deleted']
${ACCOUNT_DELETED_CONTINUE_BUTTON}      css=a[data-qa='continue-button']
