"""Worked example: a tiny checklist for the fictional app "ShopLite".

Build it to see every sheet filled in:
    python3 build_checklist.py example_data.py example.xlsx example_open_questions.md
"""

PROJECT = dict(
    name="ShopLite",
    prefix="SHP",
    project="ShopLite 1.0 - cart module",
    version="1.0 - first checklist",
    sources="shoplite-prd.md (v1.0) | shoplite-user-stories.md (v1.0, 3 stories)",
    test_site="https://shoplite.example.test (desktop web)",
    scope_note="Native mobile apps are out of scope for v1 (N/A).",
    changelog=[("2026-01-10", "First release of the checklist.")],
)

ACCOUNTS = [
    ("Admin", "admin@shoplite.example.test", "Shop Admin", "active", "(see vault)", "Admin panel", ""),
    ("Customer", "linh@shoplite.example.test", "Linh", "active", "(see vault)", "Storefront", "Registered buyer"),
]

REQS = [
    ("US-1.1", "As a shopper I can add a product to my cart", "Epic 1 - Cart", "PRD 3.1", "Implemented per doc"),
    ("US-1.2", "As a shopper I can change item quantity in my cart", "Epic 1 - Cart", "PRD 3.2", "Implemented per doc"),
    ("US-2.1", "As a shopper I can check out as a guest", "Epic 2 - Checkout", "PRD 4", "Conflicting"),
]

# (req_id, epic, feature, scenario, steps, expected, type, priority)
TCS = [
    ("US-1.1", "Epic 1 - Cart", "Add to cart", "Add an in-stock product",
     "Open a product page|Click Add to cart", "Cart badge shows 1 and the item is listed", "Functional", "Critical"),
    ("US-1.1", "Epic 1 - Cart", "Add to cart", "Add the same product twice",
     "Add a product|Add the same product again", "Quantity becomes 2, no duplicate row", "Functional", "High"),
    ("US-1.2", "Epic 1 - Cart", "Quantity", "Increase quantity to the stock limit",
     "Open the cart|Click + until stock is reached", "The + button is disabled at the stock limit", "Functional", "Medium"),
    ("US-2.1", "Epic 2 - Checkout", "Guest checkout", "Check out without an account",
     "Add a product|Go to checkout without logging in", "Order is placed (pending Q-SHP-01)", "Functional", "Critical"),
    ("US-2.1", "Epic 2 - Checkout", "Guest checkout", "Guest sees a confirmation page",
     "Place a guest order", "Confirmation page shows the order number", "UI", "Low"),
]

RESULTS = {
    "SHP-001": ("PASS", "Linh", "Round 1."),
    "SHP-002": ("FAIL", "Linh", "Duplicate row created. SHP-BUG-01"),
    "SHP-004": ("BLOCKED", "Linh", "Waiting on Q-SHP-01"),
}

ISSUES = [
    "-- Smoke test round 1 --",
    ("SHP-BUG-01", "[Cart] Adding the same product twice creates a duplicate row", "Bug", "Major",
     "US-1.1", "SHP-002", "Open for coding", "", "Smoke 2026-01-12", "Reproduced on desktop web"),
]

OQ = {
    "Q-SHP-01": dict(
        topic="Guest checkout allowed", kind="Conflict", priority="P0", tcs=["SHP-004", "SHP-005"], status="OPEN",
        options=[("A", "PRD 4", "Guests can check out."), ("B", "US-2.1", "Login is required to check out.")],
        site="The test site lets guests check out.",
        question="Which option is correct for v1?",
        docs_note="Align PRD 4 and US-2.1 once confirmed.",
        answer="",
    ),
    "Q-SHP-02": dict(
        topic="Message when stock runs out", kind="Gap", priority="P2", tcs=["(no test case yet)"], status="OPEN",
        options=[], site="",
        question="What message is shown when a product goes out of stock while it is in the cart?",
        answer="",
    ),
}
