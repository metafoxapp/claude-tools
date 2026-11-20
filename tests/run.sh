#!/usr/bin/env bash
# Runs every tests/**/test_*.sh. Exit 1 if any file fails.
cd "$(dirname "$0")" || exit 1
failed=0
for t in $(find . -name 'test_*.sh' | sort); do
  echo "== $t"
  if ! bash "$t"; then echo "!! $t FAILED"; failed=$((failed + 1)); fi
done
if [ "$failed" -gt 0 ]; then echo "$failed test file(s) failed"; exit 1; fi
echo "all tests passed"
