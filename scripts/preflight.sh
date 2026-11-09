#!/usr/bin/env bash
#
# The checks a pull request to main must pass, run locally before a commit.
# .github/workflows/text-check.yml runs this same script, so a green run here
# means a green check there.
#
#   ./scripts/preflight.sh
#
# 1. scripts/brand-check.sh and its tests. The script scans page-type files
#    only, which here means the profile (scripts/brand-check.paths).
# 2. Every other public text file (Markdown anywhere, and .github/) for the
#    same em dash, retired-phrase and banned-word rules. The brand check picks
#    files by type and a paths entry can only narrow that, so this step covers
#    what it cannot.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

step() { printf '\n==> %s\n' "$1"; }

step "Brand check"
./scripts/brand-check.sh

step "Brand check tests"
./scripts/brand-check.test.sh

step "Other public text"
git ls-files -z -- '*.md' '.github/' \
  | xargs -0 perl -ne '
      BEGIN {
        $dash    = qr/\xe2\x80\x94|&mdash;|&#8212;|&#x2014;|\\u2014/i;
        $retired = qr/technology solutions and product company|from business problems to working solutions/i;
        $banned  = qr/\b(?:best|world[- ]class|user[- ]centric|human[- ]cent(?:red|ered)|revolutioni[sz](?:e|es|ed|ing)|seamless(?:ly)?|cutting[- ]edge|unlock(?:s|ed|ing)?|game[- ]chang(?:er|ers|ing))\b/i;
        $bad = 0; $n = 0;
      }
      $n++ if $. == 1;
      for my $r (["em-dash", $dash], ["retired", $retired], ["banned", $banned]) {
        if ($_ =~ $r->[1]) { print "$ARGV:$.: [$r->[0]] $_"; $bad = 1; }
      }
      close ARGV if eof;
      END {
        print $bad ? "text check: failed\n" : "text check: clean ($n files)\n";
        exit $bad;
      }'

printf '\npreflight: green\n'
