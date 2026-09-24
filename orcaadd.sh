#!/usr/bin/env bash
# Add a project to Orca (if not registered yet), put it in a project group and focus it.
#
# Usage: orcaadd [path] [-g|--group <name|id>]
#   path          Project folder (default: current directory; git root is used when inside a repo)
#   -g, --group   Group to add the project to. Omit to pick interactively.
#                 Use "none" for no group. On an already registered project, moves it.
set -euo pipefail

ORCA_APP="/Applications/Orca.app"
ORCA_CLIENT="$ORCA_APP/Contents/Resources/app.asar.unpacked/out/cli/runtime-client.js"

usage() {
  sed -n '4,7p' "$0" | sed 's/^# \{0,1\}//'
}

# Call an Orca runtime RPC method that the `orca` CLI does not expose (e.g. projectGroup.*)
orca_rpc() {
  ELECTRON_RUN_AS_NODE=1 "$ORCA_APP/Contents/MacOS/Orca" -e '
    const { RuntimeClient } = require(process.argv[1]);
    new RuntimeClient()
      .call(process.argv[2], process.argv[3] ? JSON.parse(process.argv[3]) : undefined)
      .then((r) => console.log(JSON.stringify(r)))
      .catch((e) => { console.error(e.message); process.exit(1); });
  ' "$ORCA_CLIENT" "$@"
}

# Radio-button style picker on the terminal. Prints the chosen index to stdout.
# Args: <default index> <option>...
select_option() {
  local selected=$1
  shift
  local options=("$@")
  local count=${#options[@]}
  local key rest i

  tput civis > /dev/tty
  trap 'tput cnorm > /dev/tty' RETURN

  while true; do
    for ((i = 0; i < count; i++)); do
      if ((i == selected)); then
        printf '\r\033[K  \033[36m(•) %s\033[0m\n' "${options[i]}" > /dev/tty
      else
        printf '\r\033[K  ( ) %s\n' "${options[i]}" > /dev/tty
      fi
    done

    IFS= read -rsn1 key < /dev/tty
    if [[ $key == $'\x1b' ]]; then
      IFS= read -rsn2 -t 1 rest < /dev/tty || true
      key+=$rest
    fi
    case $key in
      $'\x1b[A' | k) selected=$(((selected - 1 + count) % count)) ;;
      $'\x1b[B' | j) selected=$(((selected + 1) % count)) ;;
      '') break ;;
      q) echo "Cancelled" >&2; return 1 ;;
    esac
    printf '\033[%dA' "$count" > /dev/tty
  done

  echo "$selected"
}

target=""
group=""
while (($#)); do
  case $1 in
    -g | --group) group=${2:?Missing value for $1}; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) target=$1; shift ;;
  esac
done

target=${target:-.}
if [[ ! -d $target ]]; then
  echo "Not a directory: $target" >&2
  exit 1
fi
root=$(git -C "$target" rev-parse --show-toplevel 2> /dev/null || (cd "$target" && pwd -P))

groups_json=$(orca_rpc projectGroup.list | jq -c '[.result.groups[] | {id, name, parentPath}]')

# Resolve --group by id or name (case-insensitive)
group_id=""
if [[ $group == none ]]; then
  group_id=none
elif [[ -n $group ]]; then
  group_id=$(jq -r --arg g "$group" \
    'map(select(.id == $g or (.name | ascii_downcase) == ($g | ascii_downcase))) | .[0].id // empty' \
    <<< "$groups_json")
  if [[ -z $group_id ]]; then
    echo "Group not found: $group" >&2
    echo "Available: $(jq -r 'map(.name) | join(", ")' <<< "$groups_json")" >&2
    exit 1
  fi
fi

if repo_json=$(orca repo show --repo "path:$root" --json 2> /dev/null); then
  current_group=$(jq -r '.result.repo.projectGroupId // "none"' <<< "$repo_json")
  current_name=$(jq -r --arg id "$current_group" 'map(select(.id == $id)) | .[0].name // "no group"' <<< "$groups_json")
  echo "Already in Orca: $root ($current_name)"
else
  if [[ -z $group_id ]]; then
    names=()
    while IFS= read -r name; do names+=("$name"); done < <(jq -r '.[].name' <<< "$groups_json")
    names+=("(no group)")

    # Preselect the group whose folder contains the project (deepest match)
    default=$(jq -r --arg p "$root" '
      to_entries
      | map(select(.value.parentPath as $pp | $pp != null and ($p | startswith($pp + "/"))))
      | max_by(.value.parentPath | length) | .key // 0' <<< "$groups_json")

    echo "Select a group for $root (↑/↓, Enter to confirm, q to cancel):" > /dev/tty
    choice=$(select_option "$default" "${names[@]}") || exit 130
    group_id=$(jq -r --argjson i "$choice" '.[$i].id // "none"' <<< "$groups_json")
  fi

  add_json=$(orca repo add --path "$root" --json)
  if ! jq -e '.ok' <<< "$add_json" > /dev/null; then
    echo "Failed to add $root to Orca" >&2
    exit 1
  fi
  current_group=$(jq -r '.result.repo.projectGroupId // "none"' <<< "$add_json")
  echo "Added to Orca: $root"
fi

current_group=${current_group:-none}
if [[ -n $group_id && $group_id != "$current_group" ]]; then
  orca_rpc projectGroup.moveProject "$(jq -nc --arg r "path:$root" --arg g "$group_id" \
    '{repo: $r, groupId: (if $g == "none" then null else $g end)}')" > /dev/null
  echo "Group: $(jq -r --arg id "$group_id" 'map(select(.id == $id)) | .[0].name // "no group"' <<< "$groups_json")"
fi

# Focus an existing terminal in the project, or open a new one focused
handle=$(orca terminal list --worktree "path:$root" --json 2> /dev/null | jq -r '.result.terminals[0].handle // empty')
if [[ -n $handle ]]; then
  orca terminal switch --terminal "$handle" > /dev/null
else
  orca terminal create --worktree "path:$root" --focus > /dev/null
fi
open -a Orca
