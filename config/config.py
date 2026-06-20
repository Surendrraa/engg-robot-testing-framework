"""
config.py - Central configuration for the AutomationExercise test suite.
"""


# Base URL of the application under test
BASE_URL = "https://www.automationexercise.com"

# Browser to use (chrome, firefox, edge)
BROWSER = "chrome"

# Default explicit-wait timeout in seconds
TIMEOUT = 30

# Run browser in headless mode (True / False)
# NOTE: Set to True for Linux/CI environments without a display.
HEADLESS = False

# Seconds to keep the headed browser visible before teardown closes it.
BROWSER_CLOSE_DELAY = 10

# Implicit wait in seconds (0 = disabled; explicit waits are preferred)
IMPLICIT_WAIT = 0
