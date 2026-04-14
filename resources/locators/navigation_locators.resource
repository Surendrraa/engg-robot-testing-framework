*** Settings ***
Documentation    Navigation and Test Cases Page locators collected from https://www.automationexercise.com/test_cases

*** Variables ***
# Test Cases Page
${TEST_CASES_HEADING}                          css=h2.title
${TEST_CASES_HEADING_ALT}                      xpath=//h2[contains(text(),'Test Cases')]
${TEST_CASE_LIST}                              css=.panel-group
${TEST_CASE_LINKS}                             css=.panel-title a

# Scroll
${SCROLL_UP_BUTTON}                            id=scrollUp
${PAGE_TOP_LOGO}                               css=.logo
${PAGE_TOP_HEADER}                             css=header
${FULL_FLEDGED_HEADING}                        xpath=//h2[contains(text(),'Full-Fledged')]
