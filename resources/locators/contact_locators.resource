*** Settings ***
Documentation    Contact Us Page locators collected from https://www.automationexercise.com/contact_us

*** Variables ***
# Page Headings
${CONTACT_US_HEADING}                          xpath=//h2[contains(text(),'Contact')]
${CONTACT_US_HEADING_ALT}                      css=.contact-form h2
${GET_IN_TOUCH_HEADING}                        xpath=//h2[contains(text(),'Get In Touch')]

# Contact Form
${CONTACT_FORM}                                id=contact-us-form
${CONTACT_NAME_INPUT}                          css=input[data-qa='name']
${CONTACT_EMAIL_INPUT}                         css=input[data-qa='email']
${CONTACT_SUBJECT_INPUT}                       css=input[data-qa='subject']
${CONTACT_MESSAGE_TEXTAREA}                    css=textarea[data-qa='message']
${CONTACT_UPLOAD_FILE_INPUT}                   css=input[name='upload_file']
${CONTACT_SUBMIT_BUTTON}                       css=input[data-qa='submit-button']

# Success Message
${CONTACT_SUCCESS_MESSAGE}                     css=.status.alert.alert-success
