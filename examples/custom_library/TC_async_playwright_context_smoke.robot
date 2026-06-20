*** Settings ***
Documentation     Low-level Playwright context smoke. Real app tests live under tests/.
Library           async_playwright_library.AsyncPlaywrightLibrary
Variables         ../../config/config.py

*** Test Cases ***
Custom Library Opens Five Contexts
    ${summary}=    Run Async Playwright Context Matrix
    ...    url=${BASE_URL}
    ...    browsers=1
    ...    contexts_per_browser=5
    ...    headless=${HEADLESS}
    ...    timeout_ms=60000
    ...    block_heavy_resources=True
    ...    hold_seconds=10
    Should Be Equal As Integers    ${summary}[total_contexts]    5
    Should Be Equal As Integers    ${summary}[browsers]    1
    Should Be Equal As Integers    ${summary}[contexts_per_browser]    5

Custom Library Keeps Context Storage Isolated
    ${summary}=    Verify Playwright Context Storage Is Isolated
    ...    contexts=5
    ...    headless=${HEADLESS}
    Should Be True    ${summary}[isolated]
    Should Be Equal As Integers    ${summary}[contexts]    5
