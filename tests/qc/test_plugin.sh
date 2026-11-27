#!/usr/bin/env bash
cd "$(dirname "$0")/../.." || exit 1
. tests/qc/lib.sh

assert_eq "0.2.0" "$(jq -r '.plugins[]|select(.name=="yn-qc")|.version' .claude-plugin/marketplace.json)" "marketplace version"
assert_eq "yn-qc" "$(jq -r .name plugins/yn-qc/.claude-plugin/plugin.json 2>/dev/null)" "plugin.json name"
assert_eq "0.2.0" "$(jq -r .version plugins/yn-qc/.claude-plugin/plugin.json 2>/dev/null)" "plugin.json version"
bash scripts/validate.sh >/dev/null 2>&1; assert_eq "0" "$?" "validate.sh exit 0"
exit $FAILS
