#!/usr/bin/env python3
"""Print a JSON description of a checklist workbook, for tests (parse with jq).

Usage: inspect_xlsx.py <file.xlsx> [Sheet!A1 ...]
Output keys: sheets, headers, dv, cells, styles, freeze, autofilter, cf,
max_tc_row, formula_max_row, formula_min_row, numeric_divisors, dimensions.
"""
import json
import re
import sys

from openpyxl import load_workbook

HEADER_ROW = {"Checklist": 2, "Account testing": 2, "RTM": 2, "Issue Log": 1, "Summary": 3, "Overview": 12}
REF = re.compile(r"Checklist!\$[A-Z]+\$3:\$[A-Z]+\$(\d+)")
DIV = re.compile(r"/\s*\d")


def row_values(ws, row):
    return [c.value for c in ws[row] if c.value is not None]


def main(path, cell_refs):
    wb = load_workbook(path)
    out = {"sheets": wb.sheetnames, "headers": {}, "dv": {}, "cells": {}, "styles": {}, "freeze": {},
           "autofilter": {}, "cf": {}, "dimensions": {}}
    max_ref, min_ref, divisors = 0, None, []
    for ws in wb:
        out["headers"][ws.title] = row_values(ws, HEADER_ROW.get(ws.title, 1))
        out["dv"][ws.title] = {
            str(dv.sqref): [v.strip('"') for v in dv.formula1.strip('"').split(",")]
            for dv in ws.data_validations.dataValidation
        }
        out["freeze"][ws.title] = ws.freeze_panes
        out["autofilter"][ws.title] = ws.auto_filter.ref
        out["cf"][ws.title] = {
            str(rng.sqref): [r.formula[0] for r in rules] for rng, rules in ws.conditional_formatting._cf_rules.items()
        }
        out["dimensions"][ws.title] = {"max_row": ws.max_row, "col_widths": {k: v.width for k, v in ws.column_dimensions.items()}}
        for row in ws.iter_rows():
            for c in row:
                if isinstance(c.value, str) and c.value.startswith("="):
                    for m in REF.finditer(c.value):
                        n = int(m.group(1))
                        max_ref = max(max_ref, n)
                        min_ref = n if min_ref is None else min(min_ref, n)
                    if DIV.search(c.value):
                        divisors.append(f"{ws.title}!{c.coordinate}")
    out["formula_max_row"] = max_ref
    out["formula_min_row"] = min_ref
    out["numeric_divisors"] = divisors
    ck = wb["Checklist"]
    out["max_tc_row"] = max((c.row for c in ck["A"] if c.row >= 3 and c.value), default=2)
    for ref in cell_refs:
        sheet, coord = ref.split("!")
        c = wb[sheet][coord]
        out["cells"][ref] = c.value
        out["styles"][ref] = {
            "fill": c.fill.fgColor.rgb[-6:] if c.fill.fill_type else None,
            "font_color": c.font.color.rgb[-6:] if c.font.color and isinstance(c.font.color.rgb, str) else None,
            "font": c.font.name, "bold": bool(c.font.b),
        }
    json.dump(out, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
