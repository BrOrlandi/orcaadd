# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-26

### Added

- `orcaadd [path] [-g|--group <name|id>]` adds a project to Orca when it isn't registered yet, puts it in a project group and focuses it.
- Interactive radio-button group picker, with the group whose folder contains the project preselected.
- `-g` on an already registered project moves it to that group; `-g none` removes it from its group.
- Focuses the project by switching to an open terminal there, or opening a new one.
- `-v, --version` prints the version.

### Fixed

- Folders that are not git repositories (for example a notes folder) are now added to Orca as plain folder projects. Before, the add failed and the script exited without printing anything.
- A failed add now prints Orca's error message.

[1.0.0]: https://github.com/BrOrlandi/orcaadd/releases/tag/v1.0.0
