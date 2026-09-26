# orcaadd

## Release & Changelog

Structured convention: `.claude/release.json` (read by the `release` skill).

- Version lives only in `orcaadd.sh` (`VERSION="X.Y.Z"`, printed by `orcaadd --version`).
- Changelog: `CHANGELOG.md` (Keep a Changelog, English), newest entry first, with a compare/tag link at the bottom.
- Tag `vX.Y.Z` (annotated), then a GitHub release whose body is the version's `CHANGELOG.md` section. No assets: people install with `git clone`.

Bump from conventional commits (breaking → major, `feat` → minor, otherwise patch), confirmed with the user. Commit as `chore(release): vX.Y.Z` with the version bump and changelog entry together.
