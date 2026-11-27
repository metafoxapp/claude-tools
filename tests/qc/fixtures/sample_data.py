"""Neutral sample data for the yn-qc checklist builder tests (ShopLite)."""

PROJECT = dict(
    name="ShopLite",
    prefix="SHP",
    project="ShopLite 1.0 — module cart",
    version="1.0 — first full checklist",
    sources="shoplite-prd.md (v1.0) · shoplite-user-stories.md (v1.0, 12 stories / 4 epics)",
    test_site="https://shoplite.example.test (desktop web)",
    scope_note="Native mobile is out of scope for v1 (N/A).",
    changelog=[("2026-01-10", "First release of the checklist."), ("2026-01-17", "Added payment edge cases.")],
)

ACCOUNTS = [
    ("Admin", "admin@shoplite.example.test", "Shop Admin", "active", "(see vault)", "Admin panel", ""),
    ("Customer", "linh@shoplite.example.test", "Linh", "active", "(see vault)", "Storefront", "Registered user"),
]

EPICS = ["Epic 1 - Browsing", "Epic 2 - Cart", "Epic 3 - Checkout", "Epic 4 - Admin"]
REQS = []
for i in range(12):
    REQS.append((f"US-{i // 3 + 1}.{i % 3 + 1}", f"Story number {i + 1}", EPICS[i // 3], f"§{i + 1}", "Implemented per doc"))
REQS.append(("US-9.9", "Story without any test case", "Epic 4 - Admin", "§9", "Revised"))

TCS = [
    ("US-1.1", EPICS[0], "Home", "Home shows the product grid", "Mở trang|Bấm Lưu", "Grid shows 12 products", "Functional", "High"),
    ("US-1.1", EPICS[0], "Home", "Product card shows price", "Mở trang chủ|Xem thẻ sản phẩm", "Card shows name, price, image", "UI", "Medium"),
    ("US-1.2", EPICS[0], "Search", "Search by name", "Gõ tên vào ô tìm kiếm|Nhấn Enter", "Matching products are listed", "Functional", "Critical"),
]
# Bulk rows (generated): 617 more, so the sheet holds 620 test cases in total.
for n in range(617):
    req = REQS[n % 12]
    TCS.append((req[0], req[2], f"Feature {n % 7}", f"Generated scenario {n}", "Step one|Step two|Step three", "Works as expected", "Functional", ["Critical", "High", "Medium", "Low"][n % 4]))

RESULTS = {
    "SHP-001": ("PASS", "Linh", "UAT run 1."),
    "SHP-002": ("FAIL", "Linh", "Price hidden on mobile web. SHP-BUG-01"),
    "SHP-003": ("KNOWN GAP", "Linh", ""),
    "SHP-004": ("BLOCKED", "", "Waiting on Q-SHP-01"),
    "SHP-005": ("N/A", "", ""),
}

ISSUES = [
    "── Smoke test round 1 ──",
    ("SHP-BUG-01", "[Home] Price hidden on mobile web", "Bug", "Major", "US-1.1", "SHP-002", "Open for coding", "", "Smoke 2026-01-12", "Seen on 375px viewport"),
    ("SHP-CLR-01", "Clarify guest checkout", "Clarification", "Minor", "US-2.1", "", "N/A", "", "Review", ""),
]

OQ = {
    "Q-SHP-01": dict(
        topic="Guest checkout allowed", kind="Conflict", priority="P0", tcs=["SHP-004"], status="OPEN",
        options=[("A", "PRD §4", "Guests can check out."), ("B", "US-3.1", "Login is required.")],
        site="The test site lets guests check out.", question="Which option is correct for v1?",
        docs_note="PRD §4 should be aligned.", answer="",
    ),
    "Q-SHP-02": dict(
        topic="Stock limit message", kind="Gap", priority="P1", tcs=["SHP-006", "(no test case yet)"], status="PARTIAL",
        options=[], site="", question="What message is shown when stock runs out?", answer="Pending.",
    ),
    "Q-SHP-03": dict(
        topic="Coupon stacking", kind="Gap", priority="P2", tcs=[], status="OPEN",
        options=[], question="Can two coupons stack?",
    ),
}
