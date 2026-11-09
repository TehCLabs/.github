#!/usr/bin/env bash
#
# Tests for scripts/brand-check.sh. Each case builds a throwaway git tree,
# runs the check there, and asserts the exit code and a line of its output.
# No network, no npm. Runs under the macOS bash 3.2 and in CI.
#
#   ./scripts/brand-check.test.sh
#
# Copied beside brand-check.sh in every repo that carries it, like the script.

set -uo pipefail

CHECK="$(cd "$(dirname "$0")" && pwd)/brand-check.sh"
pass=0
fail=0

# new_tree: an empty git repo with the check in place, as the cwd.
new_tree() {
  tree="$(mktemp -d)" || exit 1
  cd "$tree" || exit 1
  git init -q
  mkdir -p scripts
  cp "$CHECK" scripts/brand-check.sh
}

# expect NAME EXIT PATTERN: run the check, assert its exit code and that its
# output has a line matching PATTERN (an extended regex).
expect() {
  name="$1" want="$2" pattern="$3"
  git add -A >/dev/null 2>&1
  out="$(bash scripts/brand-check.sh 2>&1)"
  got=$?
  if [ "$got" = "$want" ] && printf '%s\n' "$out" | grep -qE -- "$pattern"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s: wanted exit %s and /%s/, got exit %s:\n%s\n\n' \
      "$name" "$want" "$pattern" "$got" "$out"
  fi
  cd / && rm -rf "$tree"
}

locale() { mkdir -p locales && printf '%s\n' "$@" > locales/en.json; }

new_tree; locale '{"a": "Quiet, precise software."}'
expect "clean copy passes" 0 'clean \(1 files\)'

new_tree; locale '{"a": "We build cutting-edge tools"}'
expect "a banned word fails" 1 '\[banned\]'

new_tree; locale '{"a": "Built for you — and them"}'
expect "a raw em dash fails" 1 '\[em-dash\]'

new_tree; locale '{"a": "Built for you &mdash; and them"}'
expect "an em dash entity fails" 1 '\[em-dash\]'

new_tree; locale '{' ' "a": "We build cutting' ' edge tools"' '}'
expect "a phrase wrapped at a space fails" 1 '\[banned,wraps\]'

new_tree; locale '{' ' "a": "We build cutting-' ' edge tools"' '}'
expect "a phrase wrapped after its hyphen fails" 1 '\[banned,wraps\]'

new_tree; locale '{' ' "a": "We build cutting-' ' edge tools, world-class too"' '}'
expect "a wrapped phrase is not hidden by another hit on the next line" 1 '^locales/en.json:2: \[banned,wraps\]'

new_tree; locale '{' ' "a": "We build cutting-edge tools",' ' "b": "fine"' '}'
expect "a hit on one line is not reported again as a wrap" 1 '^locales/en.json:2: \[banned\] '

new_tree; locale '{"a": "the first studio of its kind"}'
expect "a first claim fails" 1 '\[claim\]'

new_tree; locale '{"a": "rarely the first answer"}'
expect "first as a plain word passes" 0 'clean'

new_tree; locale '{"a": "We build cutting-edge tools"}'
printf '%s\n' 'cutting-edge tools' > scripts/brand-check.allow
expect "an allow rule passes a known hit" 0 'allow-listed'

new_tree; locale '{"a": "We build cutting-edge tools"}'
printf '%s\n' '([' > scripts/brand-check.allow
expect "a broken allow regex fails, not passes" 1 'regex grep cannot compile'

new_tree; mkdir -p site/a/locales site/b
printf '%s\n' '{"a": "fine"}' > site/a/locales/en.json
printf '%s\n' 'Fine.' > site/b/llms.txt
printf '%s\n' 'site/a/' 'site/b/' > scripts/brand-check.paths
expect "every paths prefix live passes" 0 'clean \(2 files\)'

new_tree; mkdir -p site/a/locales site/b
printf '%s\n' '{"a": "fine"}' > site/a/locales/en.json
printf '%s\n' 'Fine.' > site/b/llms.txt
printf '%s\n' 'site/a/' 'site/b/' 'site/gone/' > scripts/brand-check.paths
expect "one dead paths prefix among live ones fails and is named" 1 '^  site/gone/$'

new_tree; locale '{"a": "fine"}'
printf '%s\n' 'other/locales/' > scripts/brand-check.paths
expect "a paths file matching nothing fails" 1 'matched no user-facing file'

# Run directly: expect would stage the deletion, and a staged deletion is
# no longer a listed file.
run_unstaged() {
  name="$1" pattern="$2"
  out="$(bash scripts/brand-check.sh 2>&1)"; got=$?
  if [ "$got" = 1 ] && printf '%s\n' "$out" | grep -qE -- "$pattern"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1)); printf 'FAIL %s: exit %s\n%s\n\n' "$name" "$got" "$out"
  fi
  cd / && rm -rf "$tree"
}

new_tree; locale '{"a": "fine"}' && mkdir -p b/locales && printf '%s\n' '{"a": "fine"}' > b/locales/en.json
git add -A >/dev/null; rm locales/en.json
run_unstaged "a tracked file deleted but not staged fails as unreadable" '\[unreadable\]'

new_tree; locale '{"a": "fine"}'
git add -A >/dev/null
mkdir -p more/locales && printf '%s\n' '{"a": "We build cutting-edge tools"}' > more/locales/en.json
run_unstaged "an untracked file is scanned" '^more/locales/en.json:1: \[banned\]'

echo "brand-check tests: $pass passed, $fail failed"
[ "$fail" = 0 ]
