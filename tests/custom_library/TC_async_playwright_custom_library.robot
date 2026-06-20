*** Settings ***
Documentation     Demo of robotframework-parallel-playwright: run many flows
...               concurrently inside ONE shared Playwright browser (low RAM,
...               no Pabot). Site-specific flows live in the consumer module
...               examples/parallel_playwright/flows.py, not in the library.
...
...               Run:
...                 robot --pythonpath examples/parallel_playwright \
...                       --pythonpath packages/robotframework-parallel-playwright \
...                       tests/custom_library/TC_async_playwright_custom_library.robot
...
...               The deterministic tests prove the engine with no network. The
...               'live' tests hit the public automationexercise demo and depend
...               on its availability; exclude them with: robot --exclude live ...
Variables         ../../config/config.py
Library           ParallelPlaywright
...                   base_url=${BASE_URL}
...                   scenario_modules=flows

*** Variables ***
${USERS}          10

*** Test Cases ***
Many Users Run Concurrently In One Browser
    [Documentation]    ${USERS} contexts open and run together in a single
    ...                Chromium process (verify browser_processes == 1).
    ...                Deterministic: uses an in-memory page, no network.
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=local_page_loads
    ...    repeat=${USERS}
    ...    headless=${HEADLESS}
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[total]                ${USERS}
    Should Be Equal As Integers    ${summary}[passed]               ${USERS}
    Should Be Equal As Integers    ${summary}[browser_processes]    1

Each Concurrent Context Is Isolated
    [Documentation]    Every run sets a cookie in its own context and reads back
    ...                only its own value, proving session isolation.
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=local_isolated_session
    ...    repeat=${USERS}
    ...    headless=${HEADLESS}
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[passed]    ${USERS}

Active Context Throttle Is Respected
    [Documentation]    With max_active_contexts=4, the run reports the cap even
    ...                though ${USERS} scenarios are queued.
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=local_page_loads
    ...    repeat=${USERS}
    ...    headless=${HEADLESS}
    ...    max_active_contexts=4
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[max_active_contexts]    4

Watch Form Actions Across Parallel Windows
    [Documentation]    Headed-friendly: each of ${USERS} windows types a name,
    ...                clicks Greet, and shows a result. Deterministic (no network).
    ...                Run headed to watch:
    ...                  --variable HEADLESS:False  (slow_mo/hold are set below)
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=local_form_demo
    ...    repeat=${USERS}
    ...    headless=${HEADLESS}
    ...    max_active_contexts=5
    ...    slow_mo_ms=600
    ...    hold_seconds=4
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[passed]    ${USERS}

Registry Lists Consumer Scenarios
    ${names}=    List Available Scenarios
    Should Contain    ${names}    local_page_loads
    Should Contain    ${names}    search_product

Live Mixed Flows Run Together
    [Documentation]    Different real flows side by side in one browser against
    ...                the public demo site. Depends on automationexercise.com.
    [Tags]    live
    ${summary}=    Run Scenarios In Parallel
    ...    scenarios=home_page_loads,search_product,add_first_product_to_cart
    ...    headless=${HEADLESS}
    ...    block_heavy_resources=True
    ...    timeout_ms=60000
    Parallel Run Should Have Passed    ${summary}
    Should Be Equal As Integers    ${summary}[total]    3
