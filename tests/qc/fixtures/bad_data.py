"""Deliberately invalid data: exactly four errors."""

PROJECT = dict(name="ShopLite", prefix="SHP", project="ShopLite", version="1.0", sources="-", test_site="-")
ACCOUNTS = []
REQS = [("US-1.1", "Story", "Epic 1", "§1", "Implemented per doc")]
TCS = [
    ("X-9", "Epic 1", "Home", "Unknown requirement", "Step", "Ok", "Functional", "High"),
    ("US-1.1", "Epic 1", "Home", "Bad priority", "Step", "Ok", "Functional", "P0"),
]
RESULTS = {"SHP-999": ("PASS", "Linh", ""), "SHP-001": ("Passed", "Linh", "")}
