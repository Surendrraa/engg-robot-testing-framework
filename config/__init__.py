"""
config/ — Configuration Package
================================

WHY THIS __init__.py FILE EXISTS:
---------------------------------
1. Marks 'config/' as a Python package so modules can be imported:
       from config.config import BASE_URL, BROWSER, TIMEOUT
       from config.test_data import VALID_EMAIL, CARD_NUMBER

2. Without this file:
       from config.config import BASE_URL
       → ModuleNotFoundError: No module named 'config'

WHAT THIS PACKAGE CONTAINS:
----------------------------
- config.py     → Environment settings (BASE_URL, BROWSER, TIMEOUT, HEADLESS)
- test_data.py  → Test data constants (credentials, addresses, card details)

WHEN TO MODIFY:
---------------
- config.py     → When switching environments (dev/staging/prod)
- test_data.py  → When test data needs to change
"""
