# Contributing

Teh C Labs repositories are private and we do not accept external pull
requests. This document records the conventions our engineers work to, so they
are written down rather than assumed.

If you have found a security issue, follow [SECURITY.md](SECURITY.md) instead.
Do not open an issue or a pull request for it.

## Branches and pull requests

Branch from `main`, named `feat/…`, `fix/…`, `chore/…` or `docs/…`, and open
the pull request against `main`. Nothing is committed to `main` directly.

Every change goes through a pull request. The pull request is where the
reasoning is recorded: the diff shows what changed, and the description is the
only place that explains why. A repository's history outlives the people who
wrote it.

Link the issue the work belongs to with a closing keyword in the description
(`Closes #12`), so that merging the pull request closes it.

## Commits

Conventional-commit prefixes (`feat:`, `fix:`, `chore:`, `docs:`) in the
subject. Explain *why* in the body; the diff already shows what.

## Issues

Use the templates. The template you pick sets the type: bug, feature or chore.
Every template also asks for a surface (backend, web, mobile, infra or docs)
and a priority, so that work can be found, prioritised and picked up by
someone other than its author.

## Where status lives

An issue's status (planned, in progress, in review, done) lives on the
organisation's project board, and only there. Repositories do not keep it in
tracking files, and a pull request description is not a status record.

## Verification

Automated checks report; they do not substitute for judgement. A pull request
states what was actually run or inspected, and what would break if the change
is wrong. Claiming a check passed is not the same as having verified the
behaviour it was meant to cover.

## Definition of done

Merged is not done. Done is the change verified where it runs, and anything
user-facing confirmed in production rather than locally. Only then is the
issue closed and its card moved to done. A repository that sets a stricter bar
in its own documentation overrides this one.
