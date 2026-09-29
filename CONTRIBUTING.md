# Contributing

Teh C Labs repositories are private and we do not accept external pull
requests. This document records the conventions our engineers work to, so they
are written down rather than assumed.

If you have found a security issue, follow [SECURITY.md](SECURITY.md) instead —
not an issue, not a pull request.

## Branches and pull requests

Branch from the repository's working branch, named `feat/…`, `fix/…`,
`chore/…` or `docs/…`.

Every change goes through a pull request. The pull request is where the
reasoning is recorded: the diff shows what changed, and the description is the
only place that explains why. A repository's history outlives the people who
wrote it.

Link the issue the work belongs to. Closing keywords resolve an issue only when
the pull request targets the repository's default branch; where a change
reaches the default branch by another route, close the issue explicitly.

## Commits

Conventional-commit prefixes — `feat:`, `fix:`, `chore:`, `docs:` — in the
subject. Explain *why* in the body; the diff already shows what.

## Issues

Use the templates. Every issue carries a type, a priority and an area, so that
work can be found, prioritised and picked up by someone other than its author.

## Verification

Automated checks report; they do not substitute for judgement. A pull request
states what was actually run or inspected, and what would break if the change
is wrong. Claiming a check passed is not the same as having verified the
behaviour it was meant to cover.

## Definition of done

Merged is not done. Done is the change verified where it runs, its tracking
record updated in the same change, and anything user-facing confirmed in
production rather than locally. A repository that sets a stricter bar in its
own documentation overrides this one.
