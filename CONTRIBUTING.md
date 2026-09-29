# Contributing

Teh C Labs repositories are private and worked on by a small team. This file
exists so the conventions are written down in one place rather than living in
somebody's head.

## Branches and pull requests

Branch from the repository's working branch, named `feat/…`, `fix/…`,
`chore/…` or `docs/…`.

Open a pull request even when you are working alone. The PR is where the
reasoning gets recorded, and a repository's history is the only artefact that
outlives the people who wrote it.

**Closing keywords only work when the pull request targets the repository's
default branch.** `Fixes #123` in a PR onto any other branch is ignored by
GitHub — no link is created and merging closes nothing. If your repository
merges through an integration branch, close issues by hand when the change
reaches the default branch, and do not assume the keyword did it.

## Status checks are not gates

Our repositories are private on the GitHub Free plan, where rulesets and branch
protection are unavailable. CI runs and reports; it **cannot** block a merge or
a direct push.

So a green check is information, not permission, and a red one stops nothing but
you. Read the run. This changes the day the organization moves to a paid plan,
and the intent is already written into each repository's `CODEOWNERS`.

## Commits

Conventional-commit prefixes (`feat:`, `fix:`, `chore:`, `docs:`) in the
subject. Explain *why* in the body — the diff already shows what.

## Issues

Use the templates. Every issue carries a type, a priority and an area. Work that
is not filed anywhere is work nobody can pick up, and a board that does not
match reality is worse than no board.

## Definition of done

Merged is not done. Done is the change verified where it runs, the tracking
file updated in the same change, and anything user-facing confirmed on
production rather than locally. Repositories that state a stricter bar in their
own `CLAUDE.md` or `README.md` override this one.
