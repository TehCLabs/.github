#!/usr/bin/env bash
#
# Brand check. Fails when a user-facing file drifts from tehclabs.my/BRAND.md:
#
#   retired   a positioning phrase retired on 2026-10-10
#   em-dash   an em dash (U+2014), raw or written as &mdash;, &#8212;,
#             &#x2014; or \u2014
#   banned    a word on the banned list (BRAND.md section 3)
#   claim     "first" or "only" used as a claim about ourselves. The plain
#             words pass: the philosophy itself says "rarely the first".
#   wraps     added to a hit when the phrase is split across two lines.
#             llms.txt and robots.txt are hard-wrapped, so every multi-word
#             rule is also tried against each line joined to the next.
#   unreadable  a listed file that is missing or cannot be opened. A file the
#             check could not read is a failure, not a file it passed.
#
# The banned and claim lists are English. A Malay catalogue is scanned for
# retired phrases and em dashes, and for nothing else: BRAND.md has no Malay
# list yet, so "clean" says less about ms.json than about en.json.
#
# User-facing means what a stranger reads: locale catalogues, index.html,
# llms.txt, robots.txt, .well-known/security.txt, web manifests and the org
# profile README. Code comments, TRACKER and docs are history and are not
# scanned. HTML comments are skipped. Copy hardcoded in components is not
# scanned either: display copy belongs in the locale catalogues.
#
# Two optional files beside this script tune it per repo:
#   brand-check.paths   one path prefix per line; only files under them are
#                       scanned (a repo whose app UI says "Unlock" needs this).
#                       Every prefix must match at least one file, or the
#                       check FAILS and names it: that surface has moved, and
#                       a green run would be a gate with nothing behind it.
#   brand-check.allow   one extended regex per line, matched against a whole
#                       "path:line: [rule] text" hit; a match is a known
#                       false positive
#
# This file is identical in every Teh C Labs repo. The canonical copy is
# tehclabs.my/scripts/brand-check.sh: change it there, then copy it out.
# The banned list below mirrors BRAND.md, and in tehclabs.my the script fails
# if the two have drifted. Other repos do not hold BRAND.md, so the drift guard
# cannot run there and the script says so on every run.
#
# Bump VERSION on every change. Each run prints it, so a stale copy in another
# repo shows in its own CI log. scripts/brand-check.test.sh pins the behaviour
# on throwaway git trees; run it after changing this file.

set -euo pipefail
VERSION=7
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PATTERN='(^|/)(locales/[^/]+\.json|index\.html|llms\.txt|robots\.txt|\.well-known/security\.txt|[^/]+\.webmanifest|profile/README\.md)$'
SKIP='(^|/)(node_modules|dist|dist-ssr|build|\.wrangler|\.venv|\.git)/'

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Tracked AND untracked-but-not-ignored. A new file is unscanned until it
  # is added if only tracked files are listed, and a gate that hashes the tree
  # before `git add` would then pass a file this check never read.
  files="$(git ls-files -co --exclude-standard)"
else
  files="$(find . -type f | sed 's|^\./||')"
fi
files="$(printf '%s\n' "$files" | grep -E "$PATTERN" | grep -vE "$SKIP" || true)"

if [ -f scripts/brand-check.paths ]; then
  prefixes="$(grep -vE '^[[:space:]]*(#|$)' scripts/brand-check.paths || true)"
  files="$(printf '%s\n' "$files" | while IFS= read -r f; do
    printf '%s\n' "$prefixes" | while IFS= read -r p; do
      # Leading paren: bash 3.2 on macOS misparses a bare case arm inside $( ).
      case "$f" in ("$p"*) printf '%s\n' "$f"; break ;; esac
    done
  done)"
fi

# Every listed prefix must match something. One renamed surface among several
# would otherwise leave the run green with that surface unscanned.
if [ -f scripts/brand-check.paths ] && [ -n "$files" ]; then
  dead="$(printf '%s\n' "$prefixes" | while IFS= read -r p; do
    hit=""
    while IFS= read -r f; do
      case "$f" in ("$p"*) hit=1; break ;; esac
    done <<< "$files"
    [ -n "$hit" ] || printf '%s\n' "$p"
  done)"
  if [ -n "$dead" ]; then
    echo "brand check v$VERSION: failed. scripts/brand-check.paths lists a prefix that matches no user-facing file:"
    printf '%s\n' "$dead" | sed 's/^/  /'
    echo "That surface has moved or been renamed. Update the paths file."
    exit 1
  fi
fi

if [ -z "$files" ]; then
  if [ -f scripts/brand-check.paths ]; then
    echo "brand check v$VERSION: failed. scripts/brand-check.paths matched no user-facing file."
    echo "The surface it names has moved or been renamed. Update the paths file."
    exit 1
  fi
  echo "brand check v$VERSION: no user-facing files here, nothing to scan"
  exit 0
fi

if [ ! -f "$ROOT/BRAND.md" ]; then
  echo "brand check v$VERSION: BRAND.md is not in this repo, so the banned-list drift guard did not run (it runs in tehclabs.my)"
fi

hits="$(printf '%s\n' "$files" | BRAND_MD="$ROOT/BRAND.md" perl -e '
  use strict; use warnings;

  my $retired = qr/technology solutions and product company|from business problems to working solutions/i;
  my $emdash  = qr/\xe2\x80\x94|&mdash;|&#8212;|&#x2014;|\\u2014/i;
  my $banned  = qr/\b(?:best|world[- ]class|user[- ]centric|human[- ]cent(?:red|ered)|revolutioni[sz](?:e|es|ed|ing)|seamless(?:ly)?|cutting[- ]edge|unlock(?:s|ed|ing)?|game[- ]chang(?:er|ers|ing))\b/i;
  my $noun    = qr/(?:platform|product|system|studio|company|software|solution|app|application|tool|provider|service)/i;
  my $claim   = qr/\b(?:world|malaysia|asia|kuala lumpur|industry|market|country|region|nation)(?:\x27|\xe2\x80\x99)s first\b|\bfirst[- ](?:of[- ]its[- ]kind|ever)\b|\bthe first (?:and only )?(?:[\w-]+ ){0,2}$noun\b|\bthe only (?:[\w-]+ ){0,2}$noun\b|\bthe one and only\b|\bonly (?:we|teh c labs)\b/i;

  # Drift guard: every banned word BRAND.md lists must be one this script catches.
  if (-f $ENV{BRAND_MD}) {
    open my $b, "<", $ENV{BRAND_MD} or die $!;
    local $/; my $md = <$b>; close $b;
    if ($md =~ /\*\*Banned words\*\*(.*?)\*\*Banned claims/s) {
      for my $w ($1 =~ /`([^`]+)`/g) {
        print "BRAND.md: [drift] banned word \"$w\" is not caught by brand-check.sh\n" unless $w =~ /^$banned$/;
      }
    } else {
      print "BRAND.md: [drift] could not find the banned words list\n";
    }
  }

  while (my $f = <STDIN>) {
    chomp $f; next unless length $f;
    my $fh;
    unless (-f $f && open $fh, "<", $f) {
      print "$f:0: [unreadable] listed but missing or not readable\n";
      next;
    }
    local $/; my $text = <$fh>; close $fh;
    # Blank HTML comments but keep their newlines, so line numbers stay true.
    $text =~ s/<!--(.*?)-->/my $c = $1; $c =~ s{[^\n]}{}g; $c/gse if $f =~ /\.html$/;
    my @lines = split /\n/, $text, -1;
    for my $i (0 .. $#lines) {
      my $line = $lines[$i];
      my $n = $i + 1;
      my @rules;
      push @rules, "retired" if $line =~ $retired;
      push @rules, "em-dash" if $line =~ $emdash;
      push @rules, "banned"  if $line =~ $banned;
      push @rules, "claim"   if $line =~ $claim;
      my $show = $line;
      # A phrase split by a hard wrap: join this line to the next, dropping the
      # quote or comment marker the next line starts with, and try the
      # multi-word rules on the pair. Counted only when the pair holds more
      # matches of a rule than the two lines do apart, so a hit already found
      # on one line is never reported twice, and another match on either line
      # does not hide the wrapped one.
      if ($i < $#lines) {
        (my $head = $line) =~ s/\s+$//;
        (my $tail = $lines[$i + 1]) =~ s/^\s*(?:[>#]+\s*)?//;
        # A line ending in a hyphen was broken inside a compound
        # ("cutting-" then "edge"), so it joins with no space.
        my $pair = $head =~ /-$/ ? "$head$tail" : "$head $tail";
        my @wrapped;
        for my $r (["retired", $retired], ["banned", $banned], ["claim", $claim]) {
          my ($name, $re) = @$r;
          my $in_pair = () = $pair =~ /$re/g;
          my $in_head = () = $line =~ /$re/g;
          my $in_tail = () = $lines[$i + 1] =~ /$re/g;
          push @wrapped, $name if $in_pair > $in_head + $in_tail;
        }
        if (@wrapped) { push @rules, @wrapped, "wraps"; $show = $pair; }
      }
      next unless @rules;
      $show =~ s/^\s+//;
      $show = substr($show, 0, 150) . "..." if length($show) > 150;
      print "$f:$n: [" . join(",", @rules) . "] $show\n";
    }
  }
')"

allowed=""
if [ -n "$hits" ] && [ -f scripts/brand-check.allow ]; then
  rules="$(grep -vE '^[[:space:]]*(#|$)' scripts/brand-check.allow || true)"
  if [ -n "$rules" ]; then
    # grep exits 1 for "no line matched", which is fine, and 2 for a regex it
    # cannot compile. Swallowing the 2 would empty $hits and print "clean".
    rc=0
    allowed="$(printf '%s\n' "$hits" | grep -E -f <(printf '%s\n' "$rules"))" || rc=$?
    if [ "$rc" -gt 1 ]; then
      echo "brand check v$VERSION: failed. scripts/brand-check.allow holds a regex grep cannot compile."
      exit 1
    fi
    rc=0
    hits="$(printf '%s\n' "$hits" | grep -vE -f <(printf '%s\n' "$rules"))" || rc=$?
    if [ "$rc" -gt 1 ]; then
      echo "brand check v$VERSION: failed. scripts/brand-check.allow holds a regex grep cannot compile."
      exit 1
    fi
  fi
fi

count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
if [ -n "$allowed" ]; then
  echo "brand check: allow-listed false positives:"
  printf '%s\n' "$allowed" | sed 's/^/  /'
fi
if [ -n "$hits" ]; then
  echo "brand check v$VERSION: failed. See tehclabs.my/BRAND.md sections 3 and 4."
  printf '%s\n' "$hits"
  exit 1
fi
echo "brand check v$VERSION: clean ($count files)"
