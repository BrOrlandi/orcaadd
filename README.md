# orcaadd

A small CLI for [Orca](https://github.com/stablyai/orca) that adds a project in one command. It registers the folder if Orca doesn't know it yet, puts it in the project group you pick, and focuses it.

```
$ orcaadd ~/Projects/my-app
Select a group for /Users/me/Projects/my-app (↑/↓, Enter to confirm, q to cancel):
  (•) My Projects
  ( ) HomeLab
  ( ) Work
  ( ) (no group)
Added to Orca: /Users/me/Projects/my-app
Group: My Projects
```

## What it does

1. Resolves the project root. It uses the path you pass, or the current directory, and the git root when the folder is inside a repo.
2. If the project is already in Orca, it prints `Already in Orca: <path> (<group>)`. Otherwise it adds it with `orca repo add`.
3. Picks the group. Without `--group` it shows a radio-button picker. The group whose folder contains the project comes preselected.
4. Focuses the project. It switches to a terminal that is already open there, or opens a new one, and brings Orca to the front.

## Usage

```
orcaadd [path] [-g|--group <name|id>]
```

| Command | Result |
|---|---|
| `orcaadd` | Current directory, interactive group picker |
| `orcaadd ../other-project` | Another path |
| `orcaadd -g work` | Group by name (case-insensitive) or id, no picker |
| `orcaadd -g none` | No group |
| `orcaadd -g homelab` on an existing project | Moves it to that group |

Picker keys: `↑`/`↓` or `j`/`k` to move, `Enter` to confirm, `q` to cancel.

## Requirements

- macOS, with Orca installed at `/Applications/Orca.app` and its `orca` CLI on your `PATH`
- `jq` (`brew install jq`)
- `git`, and `bash` 3.2 or newer (the one that ships with macOS works)

## Install

```sh
git clone https://github.com/BrOrlandi/orcaadd.git ~/Projects/orcaadd
sudo ln -s ~/Projects/orcaadd/orcaadd.sh /usr/local/bin/orcaadd
```

Or add an alias to your shell config instead of the symlink:

```sh
alias orcaadd="$HOME/Projects/orcaadd/orcaadd.sh"
```

## How it works

Most steps use the public `orca` CLI (`repo show`, `repo add`, `terminal list`, `terminal switch`, `terminal create`). The CLI has no commands for project groups. For those, the script loads the runtime client that ships inside the Orca app bundle and calls the runtime's `projectGroup.list` and `projectGroup.moveProject` methods.

Those methods are internal and not a public API. An Orca update may rename or change them. Tested with Orca CLI 1.4.210.

## License

MIT
