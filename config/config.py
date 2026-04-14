"""
config.py - Central configuration for the AutomationExercise test suite.
"""


# Base URL of the application under test
BASE_URL = "https://www.automationexercise.com"

# Browser to use (chrome, firefox, edge)
BROWSER = "chrome"

# Default explicit-wait timeout in seconds
TIMEOUT = 10

# Run browser in headless mode (True / False)
# NOTE: Set to True for Linux/CI environments without a display.
HEADLESS = True

# Implicit wait in seconds (0 = disabled; explicit waits are preferred)
IMPLICIT_WAIT = 0
