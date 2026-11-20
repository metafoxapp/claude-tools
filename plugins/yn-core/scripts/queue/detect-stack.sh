#!/usr/bin/env bash
# Usage: detect-stack.sh
# Prints the best-matching preset name for the current repository.
set -euo pipefail
. "$(dirname "$0")/common.sh"
root=$(yn_repo_root)

if [ -f "$root/composer.json" ] && grep -q 'laravel/framework' "$root/composer.json"; then
  echo laravel
elif [ -f "$root/pom.xml" ] && grep -qi 'cucumber' "$root/pom.xml"; then
  echo java-e2e
elif [ -f "$root/package.json" ]; then
  echo node
else
  echo generic
fi
